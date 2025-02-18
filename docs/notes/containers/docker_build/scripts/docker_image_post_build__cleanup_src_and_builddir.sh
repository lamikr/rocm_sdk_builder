cd /rocm_sdk_builder
find ./builddir -name ".result_build" -o -name ".result_config" -o -name ".result_install" -o -name ".result_postconfig" -o -name ".result_postinstall" -o -name ".result_preconfig" | tar -cvf builddir_resultfiles.tar -T -
rm -rf builddir
rm -rf src_projects
tar -xvf builddir_resultfiles.tar
rm -f builddir_resultfiles.tar
