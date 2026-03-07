# RHEL7に新しいglib,gccを入れて、VSCode1.86以降のバージョンのリモート拡張機能を使えるようにする方法

## 1.概要

この記事はダウンロード環境とターゲットの RHEL7計算機が別の計算機である想定で、RHEL7 に新しい glib,gcc を入れて、VSCode1.86以降のバージョンのリモート拡張機能を使えるようにする方法を記載する。

> 古いLinuxでVSCodeのリモート機能がサポート対象外になったので、それの回避策の覚え書き。

詳細は[こちら](https://code.visualstudio.com/docs/remote/linux)を参照。

平たく言うと、__古い linuxディストリビューションは glib,libstdc++ のバージョンが古いので対象外だよ__ ということ。

対策は __glib,libstdc++ の tarball をビルドして、システムへの影響の無いようにカスタムのインストール先にインストール__ してしまえば良い。

ちなみに、`glibc` や `libstdc++` をシステムのパスの通ったところにインストールしたり、環境変数 `LD_LIBRARY_PATH` にパスを追加するとシステムが壊れる。基本コマンドも使えなくなる。絶対にやらないこと。

- この記事の動作確認をした環境は以下のとおり

  - Windows11 に CentOS7.5 の WSL2 ディストリビューションを作成
  - VSCode1.109.5 の拡張機能WSLでリモート接続

- tarballをビルドしてカスタムインストールするパッケージは以下のとおり

  | コンポーネント | カスタムのインストール先 |
  | --- | --- |
  | glib2.29 | /opt/glibc-2.29 |
  | gcc12.2 | /opt/gcc-12.2 |
  | patchelf0.18 | /opt/patchelf0.18 |

## 2. ダウンロード

必要な資材のダウンロードの手順を以下にまとめる

Windows11で資材をダウンロードする場合は[こちら](https://github.com/fangface-hub/devtoolset_glib_gcc_patchelf_download_script)をクローンしてスクリプトを使う。

### 2.1. 予めターゲットのRHEL7計算機にカスタムビルドに必要な追加パッケージをインストールする

ターゲットのRHEL7計算機で以下のコマンドを実行する

```bash
sudo yum groupinstall -y "Development Tools"
sudo yum install -y gmp-devel mpfr-devel libmpc-devel \
    bison flex wget tar xz
```

### 2.2. オンライン端末で devtoolset-11 と関連パッケージをダウンロードする

> crosstool-ng を使う方法もあるが、必要な資材が多いので devtoolset-11 が安全で最短。

- オンライン端末がRHEL7の場合

  1. yum でダウンロードする

     ```bash
     sudo yum install --downloadonly --downloaddir=./devtoolset11_rpms \
         devtoolset-11 devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils \
         scl-utils-20130529-19 scl-utils-build-20130529-19
     ```

  1. ターゲットのRHEL7計算機に `devtoolset11_rpms` ディレクトリを移動する

- オンライン端末がWindowsの場合

  1. ダウンロードスクリプト `devtoolset11download.ps1` を右クリックしPowershellで実行する

  1. `devtoolset11download.ps1` を右クリックし、PowerShellで実行する

  1. ターゲットのRHEL7計算機に `devtoolset11_rpms` ディレクトリを移動する

### 2.3. glib2.29をダウンロードする

- オンライン端末がRHEL7の場合

  1. curlでダウンロードする

      ```bash
      mkdir glib2.29_tarball
      cd glib2.29_tarball
      curl -O https://ftp.gnu.org/gnu/glibc/glibc-2.29.tar.gz
      ```

  1. ターゲットのRHEL7計算機に `glib2.29_tarball` ディレクトリを移動する

- オンライン端末がWindowsの場合

  1. ダウンロードスクリプト `glib2.29download.ps1` を右クリックしPowershellで実行する
  
  1. ターゲットのRHEL7計算機に `glib2.29_tarball` ディレクトリを移動する

### 2.4. gcc12.2 をダウンロードする

- オンライン端末がRHEL7の場合

  1. curlでダウンロードする

      ```bash
      mkdir gcc12.2_tarball
      cd gcc12.2_tarball
      # GCC本体
      curl -O https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz
      # GMP（GNU Multiple Precision Arithmetic Library）
      curl -O https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz
      # MPFR（Multiple Precision Floating-Point Reliably）
      curl -O https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz
      # MPC（Multiple Precision Complex）
      curl -O https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz
      ```

  1. ターゲットのRHEL7計算機に `gcc12.2_tarball` ディレクトリを移動する

- オンライン端末がWindowsの場合

  1. ダウンロードスクリプト `gcc12.2download.ps1` を右クリックしPowerShellで実行する

  1. ターゲットのRHEL7計算機に `gcc12.2_tarball` ディレクトリを移動する

### 2.5 patchelf-0.18 のダウンロード

- オンライン端末がRHEL7の場合

  1. curlでダウンロードする
  
      ```bash
      mkdir patchelf0.18_tarball
      curl -LO https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0.tar.gz
      ```

  1. ターゲットのRHEL7計算機に `patchelf0.18_tarball` ディレクトリを移動する

- オンライン端末がWindowsの場合

  1. ダウンロードスクリプト `patchelf0.18download.ps1` を右クリックしPowerShellで実行する

  1. ターゲットのRHEL7計算機に `patchelf0.18_tarball` ディレクトリを移動する

## 3. インストール

インストール手順を3章にまとめる

### 3.1. devtoolset-11をインストールする

1. ターゲットのRHEL7計算機で以下のコマンド

    ```bash
    cd devtoolset11_rpms
    sudo rpm -Uvh --force \
        libgfortran5*.rpm \
        scl-utils-*.rpm \
        devtoolset11*.rpm
    ```

    > エラーになったら `devtoolset11_rpms` の中から必要な依存パッケージを追加する。依存パッケージを全てダウンロードしているはず。

### 3.2. glib2.29 をビルド、インストールする

1. devtoolset-11 を有効にする

    ```bash
    scl enable devtoolset-11 bash
    ```

1. そのまま同じ端末で glib2.29 をビルドする

    ```bash
    cd glib2.29_tarball # 格納したディレクトリへ移動
    tar xf glibc-2.29.tar.gz # 圧縮ファイルを展開
    cd glibc-2.29 # 展開先へ移動
    mkdir build # ビルドディレクトリ作成
    cd build # ビルドへ移動
    
    # configure
    ../configure \
        --prefix=/opt/glibc-2.29 \
        --disable-werror
    make -j$(nproc) # make
    sudo make install # make install
    ```

### 3.3. gcc12.2をビルド、インストールする

1. devtoolset-11 を有効にする

    ```bash
    scl enable devtoolset-11 bash
    ```

1. そのまま同じ端末で gcc12.2 をビルドする

    ```bash
    cd gcc12.2_tarball
    tar xf gcc-12.2.0.tar.xz
    tar xf gmp‑6.2.1.tar.xz
    tar xf mpfr-4.1.0.tar.xz
    tar xf mpc-1.2.1.tar.gz
    cd gcc-12.2.0
    
    # 必要なライブラリを GCC ソースツリーに配置
    ln -s ../gmp-6.2.1 gmp
    ln -s ../mpfr-4.1.0 mpfr
    ln -s ../mpc-1.2.1 mpc
    
    mkdir build
    cd build

    GLIB_PATH=/opt/glibc-2.29/lib
    GLIBC_LINKER=/opt/glibc-2.29/lib/ld-linux-x86-64.so.2
    export CC="gcc -Wl,--dynamic-linker=${GLIBC_LINKER} -Wl,--rpath=${GLIB_PATH}"
    export CXX="g++ -Wl,--dynamic-linker=${GLIBC_LINKER} -Wl,--rpath=${GLIB_PATH}"

    ../configure \
      --prefix=/opt/gcc-12.2 \
      --disable-multilib \
      --enable-languages=c,c++

    make -j$(nproc) 
    sudo make install
    ```

### 3.4. patchelf0.18 をビルド、インストールする

1. devtoolset-11 を有効にする

    ```bash
    scl enable devtoolset-11 bash
    ```

1. そのまま同じ端末で patchelf0.18 をビルドする

    ```bash
    tar xf patchelf-0.18.0.tar.gz
    cd patchelf-0.18.0
    ./configure --prefix=/opt/patchelf0.18
    make -j$(nproc)
    sudo make install
    ```

## 4. ターゲットのRHEL7計算機の環境変数を設定する

システムの環境変数を変更すると古いVSCodeを使っているユーザにも影響してしまうので、なるべく個人のプロファイルを設定する。

`~.bashrc` と `~/.vscode-server/server-env-setup` に以下の環境変数を追加する

```bash
# 省略(既存の行は変更しない)
GCC12_2_LIB=/opt/gcc-12.2/lib64
GLIBC2_29_LIB=/opt/glibc-2.29/lib
PATCHELF0_18=/opt/patchelf0.18
export VSCODE_LD_LIBRARY_PATH=${GCC12_2_LIB}:${GLIBC2_29_LIB}
export VSCODE_SERVER_CUSTOM_GLIBC_LINKER=${GLIBC2_29_LIB}/ld-linux-x86-64.so.2
export VSCODE_SERVER_CUSTOM_GLIBC_PATH=${VSCODE_LD_LIBRARY_PATH}
export VSCODE_SERVER_PATCHELF_PATH=${PATCHELF0_18}/bin/patchelf
```
