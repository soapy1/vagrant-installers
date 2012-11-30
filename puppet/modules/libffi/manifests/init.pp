# == Class: libffi
#
# Installs libffi.
#
class libffi (
  $autotools_environment = {},
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
  $prefix = params_lookup('prefix'),
) {
  require build_essential

  $source_filename  = "libffi-3.0.11.tar.gz"
  $source_file_path = "${file_cache_dir}/${source_filename}"
  $source_dir_name  = regsubst($source_filename, '^(.+?)\.tar\.gz$', '\1')
  $source_dir_path  = "${file_cache_dir}/${source_dir_name}"

  # Determine if we have an extra environmental variables we need to set
  # based on the operating system.
  if $operatingsystem == 'Darwin' {
    $extra_autotools_environment = {
      "LDFLAGS" => "-Wl,-install_name,@rpath/libffi.dylib",
    }
  } else {
    $extra_autotools_environment = {}
  }

  # Merge our environments.
  $real_autotools_environment = autotools_merge_environments(
    $autotools_environment, $extra_autotools_environment)

  #------------------------------------------------------------------
  # Compile
  #------------------------------------------------------------------
  wget::fetch { "libffi":
    source      => "ftp://sourceware.org/pub/libffi/${source_filename}",
    destination => $source_file_path,
  }

  exec { "untar-libffi":
    command => "tar xvzf ${source_file_path}",
    creates => $source_dir_path,
    cwd     => $file_cache_dir,
    require => Wget::Fetch["libffi"],
  }

  autotools { "libffi":
    configure_flags => "--prefix=${prefix} --disable-debug --disable-dependency-tracking",
    cwd             => $source_dir_path,
    environment     => $real_autotools_environment,
    require         => Exec["untar-libffi"],
  }

  #------------------------------------------------------------------
  # Extra hacks
  #------------------------------------------------------------------
  # We need to move the headers out to a standard place so that things
  # can properly link against libffi. We do this by just making a symlink.
  file { "${prefix}/include/ffi.h":
    ensure  => link,
    target  => "../lib/${source_dir_name}/include/ffi.h",
    require => Autotools["libffi"],
  }

  file { "${prefix}/include/ffitarget.h":
    ensure  => link,
    target  => "../lib/${source_dir_name}/include/ffitarget.h",
    require => Autotools["libffi"],
  }
}
