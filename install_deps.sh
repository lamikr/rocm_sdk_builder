func_is_supported_distro()
{
  if [ -z ${ID+foo} ]; then
    printf "Error, Linux distribution ID could not be read from /etc/os-release\n"
    exit 2
  fi

  case "${ID}" in
    mageia|fedora|ubuntu)
        echo "Supported Linux distribution detected: ${ID}"
        true
        ;;
    *)  printf "This script is currently supported on Mageia, Fedora and Ubuntu\n"
        exit 2
        ;;
  esac
}

func_install_packages()
{
    case "${ID}" in
        mageia)
          sudo urpmi cmake rpm-build gcc gcc-c++ gcc-c++-x86_64-linux-gnu lld golang libstdc++-static-devel openssl-devel zlib-devel gcc-gfortran make fftw-devel wget libdrm-devel glew-devel autoconf automake libtool icu bzip2-devel perl-base python-pip python-wheel python3-numpy python3-wheel python3-mock python3-future python3-pip python3-yaml python3-setuptools numa-devel libstdc++6 libstdc++-devel valgrind-devel lib64llvm-devel lib64boost_thread1.81.0 lib64boost_math1.81.0 lib64boost-devel lib64clang15.0 python3-ply python3-joblib python3-lit lib64msgpack-devel libffi-devel json-devel texinfo git git-lfs bison flex byacc gettext xz-devel ninja-build texlive-dist opencl-devel protobuf-devel pybind11-devel lib64aio-devel
          pip3 install --user CppHeaderParser
	      git-lfs install
          ;;
        fedora)
          # elevate_if_not_root dnf -y update
          sudo dnf install cmake rpm-build gcc gcc-c++ openssl-devel zlib-devel gcc-gfortran make libcxx-devel numactl-libs numactl-devel dpkg-dev doxygen  elfutils-libelf-devel prename perl-URI-Encode perl-File-Listing perl-File-BaseDir fftw-devel wget libdrm-devel xxd glew-devel python3-cppheaderparser autoconf automake libtool icu bzip2-devel lzma-sdk-devel libicu-devel msgpack-devel libffi-devel json-devel texinfo python3-pip sqlite-devel git git-lfs lbzip2 opencv-devel ffmpeg-free valgrind perl-FindBin pmix-devel flex-devel bison-devel bison flex byacc gettext xz-devel ninja-build texlive-scheme-small protobuf-devel pybind11-devel libaio-devel
	      git-lfs install
          ;;
        ubuntu)
          # elevate_if_not_root apt-get update
          sudo apt install gfortran make pkg-config libnuma1 cmake-curses-gui dpkg-dev rpm doxygen libelf-dev rename liburi-encode-perl libfile-basedir-perl libfile-copy-recursive-perl libfile-listing-perl build-essential wget libomp5 libomp-dev libpci3 libdrm-dev xxd libglew-dev autoconf automake libtool libbz2-dev liblzma-dev libicu-dev libfindbin-libs-perl libmsgpack-dev python3-pip libssl-dev python3-openssl libffi-dev nlohmann-json3-dev texinfo libnuma-dev cmake-extras cmake-gui sqlite3 libsqlite3-dev git git-lfs lbzip2 valgrind bison flex byacc gettext ninja-build texlive ocl-icd-opencl-dev protobuf-compiler pybind11-dev libaio-dev
          pip3 install --break-system-packages --user CppHeaderParser
	      git-lfs install
          ;;
         *)
          echo "This script is currently supported on Mageia, Fedora and Ubuntu"
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
            echo ""
            exit 2
        fi
    else
        echo ""
        echo "You need to configure git user's name and email address. Example commands:"
        echo "    git config --global user.name \"John Doe\""
        echo "    git config --global user.email \"john.doe@emailserver.com\""
        echo ""
        exit 2
    fi
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
echo "Dependencies installed, you can now start using the babs.sh command"
