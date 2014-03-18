define opendj::instance (
  $version,
  $base_dn,
  $admin_pw,
  $instance        = $name,
  $ldap_port  	   = '1389',
  $ldaps_port      = '1636',
  $admin_port 	   = '5444',
  $jmx_port   	   = '1689',
  $admin_cn   	   = 'Directory\ Manager',
  $ssl_certificate = undef,
  $java_version    = 'openjdk_1_7_0',
) {
  include opendj

  $instance_home = "/opt/opendj/instances/${instance}"

  $java_class_name = "::java::${java_version}"

  if (!defined(Class[$java_class_name])) {
    class { $java_class_name: }
  }

  user { $name:
    home     => $instance_home,
    password => '!',
    ensure   => present,
    comment  => 'OpenDJ user',
  }

  file { $instance_home:
    ensure => directory,
    owner  => $instance,
    group  => $instance,
  }

  if(!defined(Maven["/usr/share/java/opendj-server-${version}.zip"])) {
    maven { "/usr/share/java/opendj-server-${version}.zip":
      id    => "org.forgerock.opendj:opendj-server:${version}:zip",
      repos => 'http://maven.forgerock.org/repo/releases',
    }
  }

  exec { "${instance}:unzip":
    command => "/usr/bin/sudo -u ${instance} /usr/bin/unzip /usr/share/java/opendj-server-${version}.zip -d ${instance_home}",
    creates => "${instance_home}/opendj",
    notify  => Exec["${instance}:setup"],
    require => [File[$instance_home],Maven["/usr/share/java/opendj-server-${version}.zip"]],
  }

  if($ssl_certificate) {
    file { "${instance_home}/ssl":
      ensure  => directory,
      owner   => $instance,
      group   => $instance,
      require => Exec["${instance}:unzip"],
    }
    
    file { "${instance_home}/ssl/keystore.pk12":
      source => $ssl_certificate,
      owner  => $instance,
      group  => $instance,
      mode   => '0640',
    }
  }

  $install_cert = $ssl_certificate ? {
    undef   => '',
    default => "-Z ${ldaps_port} --usePkcs12keyStore '${instance_home}/ssl/keystore.pk12' -W changeit --enableStartTLS",
  }

  $require = $ssl_certificate ? {
    undef   => undef,
    default => File["${instance_home}/ssl/keystore.pk12"],
  }

  exec { "${instance}:setup":
    command     => "/usr/bin/sudo -u ${instance} ${instance_home}/opendj/setup -i -b ${base_dn} -a -p ${ldap_port} --adminConnectorPort ${admin_port} -D cn=${admin_cn} -w ${admin_pw} -n --noPropertiesFile ${install_cert} --acceptLicense",
    refreshonly => true,
    require     => $require,
    before      => Exec["${instance}:startup"],
  }
  
  exec { "${instance}:startup":
    command => "/usr/bin/sudo -u ${instance} ${instance_home}/opendj/bin/start-ds",
    unless  => "/bin/ps aux | /bin/grep 'org.opends.server.core.DirectoryServer' | /bin/grep 'org.opends.server.extensions.ConfigFileHandler' |/bin/grep '${instance}\/opendj'",
  }
}
