#!/usr/bin/env bash
source build/system_utils.sh

func_is_supported_distro()
{
    if [ -z ${ID+foo} ]; then
        printf "Error, Linux distribution ID could not be read from /etc/os-release\n"
        exit 2
    fi

    case "${ID}" in
        mageia|fedora|ubuntu|linuxmint|arch|manjaro|void)
            echo "Supported Linux distribution detected: ${ID}"
            true
        ;;
    *)
        echo "Unsupported Linux distribution detected: ${ID} $VERSION_ID"
        printf "This script is currently supported on Mageia, Fedora, Ubuntu, Linux Mint, Arch, Manjaro and Void\n"
        exit 2
        ;;
    esac
}

func_install_packages()
{
    case "${ID}" in
        mageia)
            sudo urpmi cmake rpm-build gcc gcc-c++ gcc-c++-x86_64-linux-gnu lld golang libstdc++-static-devel openssl-devel zlib-devel gcc-gfortran make fftw-devel wget libdrm-devel glew-devel autoconf automake libtool icu bzip2-devel perl-base python-pip python-wheel python3-numpy python3-wheel python3-mock python3-future python3-pip python3-yaml python3-setuptools numa-devel libstdc++6 libstdc++-devel valgrind-devel lib64llvm-devel lib64boost_thread1.81.0 lib64boost_math1.81.0 lib64boost-devel lib64clang15.0 python3-ply python3-joblib python3-lit lib64msgpack-devel libffi-devel json-devel texinfo git git-lfs openpmix-devel bison flex byacc gettext xz-devel ninja-build texlive-dist opencl-devel protobuf-devel pybind11-devel lib64aio-devel gmp-devel mpfr-devel png-devel jpeg-devel lib64sox3 ncurses-devel systemd-devel expat-devel babeltrace-devel lmdb-devel opencv-devel zstd-devel dyninst-devel pfm-devel lib64va-devel cpio
            pip3 install --user CppHeaderParser
            git-lfs install
            ;;
        fedora)
            # elevate_if_not_root dnf -y update
            sudo dnf install cmake rpm-build gcc gcc-c++ openssl-devel zlib-devel gcc-gfortran make libcxx-devel numactl-libs numactl-devel dpkg-dev doxygen  elfutils-libelf-devel prename perl-URI-Encode perl-File-Listing perl-File-BaseDir fftw-devel wget libdrm-devel xxd glew-devel python3-cppheaderparser autoconf automake libtool icu bzip2-devel lzma-sdk-devel libicu-devel msgpack-devel libffi-devel json-devel texinfo python3-pip sqlite-devel git git-lfs lbzip2 ffmpeg-free valgrind perl-FindBin pmix-devel flex-devel bison-devel bison flex byacc gettext xz-devel ninja-build texlive-scheme-small protobuf-devel pybind11-devel libaio-devel gmp-devel mpfr-devel libpng-devel libjpeg-devel sox ncurses-devel systemd-devel expat-devel libbabeltrace-devel lmdb-devel opencv-devel libzstd-devel libva-devel gettext-devel curl-devel cpio
            git-lfs install
            ;;
        ubuntu|linuxmint)
            # elevate_if_not_root apt-get update
            sudo apt install -y gfortran make pkg-config libnuma1 cmake-curses-gui dpkg-dev rpm doxygen libelf-dev rename liburi-encode-perl libfile-basedir-perl libfile-copy-recursive-perl libfile-listing-perl build-essential wget libomp5 libomp-dev libpci3 libdrm-dev xxd libglew-dev autoconf automake libtool libbz2-dev liblzma-dev libicu-dev libfindbin-libs-perl libmsgpack-dev python3-pip libssl-dev python3-openssl libffi-dev nlohmann-json3-dev texinfo libnuma-dev cmake-extras cmake-gui sqlite3 libsqlite3-dev git git-lfs lbzip2 valgrind libpmix-dev bison flex byacc gettext ninja-build texlive ocl-icd-opencl-dev protobuf-compiler pybind11-dev libaio-dev libgmp-dev libmpfr-dev libpng-dev libjpeg-dev sox ncurses-dev libsystemd-dev libexpat1-dev libbabeltrace-dev liblmdb-dev libopencv-dev libzstd-dev libva-dev autopoint gawk libcurl4-openssl-dev cpio
            pip3 install --break-system-packages --user CppHeaderParser
            res=$?
            if [ $res != 0 ]; then
                # ubuntu 22.04/Mint 21 returns error for "--break-system-packages" demand, while newer versions require it.
                # In this case try to install again without "--break-system-packages" argument
                pip3 install --user CppHeaderParser
            fi
            # Ubuntu 22.04 and Mint Linux 21 (based on to ubuntu 22.04) need special care
            # They both require the install of newer libstdc++-12-dev, libgfortran-12-dev and gfortran-12
            # some package will otherwise fails to find <cmath> and hipBLASLT on the otherwise will fail
            # to link with the older libgfortran from 11-version that is installed by default
            # https://stackoverflow.com/questions/22752000/clang-cmath-file-not-found
            case "$VERSION_ID" in
                21.*|22.04)
                    sudo apt install libstdc++-12-dev libgfortran-12-dev gfortran-12
                    ;;
                *)
                    ;;
            esac
            git-lfs install
            ;;
        arch|manjaro)
            # elevate_if_not_root pacman -Syu
            sudo pacman -S --needed gcc-libs make pkgconf numactl cmake doxygen libelf perl-rename perl-uri perl-file-basedir perl-file-copy-recursive perl-file-listing wget gcc gcc-fortran gcc-libs fakeroot openmp pciutils libdrm vim glew autoconf automake libtool bzip2 xz icu perl libmpack python-pip openssl python-pyopenssl libffi nlohmann-json texinfo extra-cmake-modules sqlite git git-lfs valgrind openpmix flex byacc gettext ninja texlive-basic ocl-icd protobuf pybind11 libaio gmp mpfr libpng libjpeg-turbo python-cppheaderparser msgpack-c msgpack-cxx sox ncurses expat systemd cpio
            git-lfs install
            ;;
        void)
            sudo xbps-install -S git-lfs base-devel gcc-fortran cmake doxygen babeltrace-devel bzip2-devel elfutils-devel expat-devel ffmpeg ffmpeg-devel gdb gdbm-devel gmp-devel icu icu-devel json-c++ lcov libaio-devel libdrm-devel libffi-devel libglvnd-devel libgomp-devel libjpeg-turbo-devel liblzma liblzma-devel libnuma-devel libpng-devel libuuid-devel mpfr-devel msgpack-cxx ncurses-devel ninja openssl-devel protobuf protobuf-devel python3-pip python3-pybind11 readline readline-devel sox sqlite sqlite-devel xxd zlib-devel
            python3 -m pip install --break-system-packages CppHeaderParser
            git-lfs install
	    ;;
        *)
            echo "Unsupported Linux distribution detected: ${ID} $VERSION_ID"
            echo "This script is currently supported on Mageia, Fedora, Ubuntu, Linux Mint, Arch, Manjaro and Void"
            exit 2
            ;;
    esac
}

func_is_git_configured() {
    GIT_USER_NAME=`git config --get user.name`
    if [ ! -z "${GIT_USER_NAME}" ]; then
        GIT_USER_EMAIL=`git config --get user.email`
        if [ ! -z "${GIT_USER_EMAIL}" ]; then
		    true
        else
            echo ""
            echo "You need to configure git user's email address. Example command:"
            echo "    git config --global user.email \"john.doe@emailserver.com\""
            echo "Some git commands used by the tool does not work with without configuring the git user."
            return 1
        fi
    else
        echo ""
        echo "You need to configure git user's name and email address. Example commands:"
        echo "    git config --global user.name \"John Doe\""
        echo "    git config --global user.email \"john.doe@emailserver.com\""
        echo "Some git commands used by the tool does not work without configuring the git user."
        return 1
    fi
    return 0
}

# /etc/*-release files describe the system
if [[ -e "/etc/os-release" ]]; then
    source /etc/os-release
elif [[ -e "/etc/centos-release" ]]; then
    ID=$(cat /etc/centos-release | awk '{print tolower($1)}')
    VERSION_ID=$(cat /etc/centos-release | grep -oP '(?<=release )[^ ]*' | cut -d "." -f1)
else
    echo "This script depends on the /etc/*-release files"
    exit 2
fi

# The following function exits script if an unsupported distro is detected
func_is_supported_distro
func_install_packages
func_is_git_configured
res=$?
func_is_user_in_dev_kfd_render_group #From system_utils.sh
res2=$?
if [[ ${res} == 0 && ${res2} == 0 ]]; then
    echo ""
    echo "Dependencies installed, you can now start using the babs.sh command"
else
    echo ""
    echo "Errors detected, fix them by following advices and run this script again to verify that they are fixed"
fi
