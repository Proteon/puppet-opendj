class opendj {
  file { ['/opt/opendj', '/opt/opendj/instances']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }
  
  file { '/etc/opendj.d': ensure => directory, }

  file { '/etc/init.d/opendj':
    source => 'puppet:///modules/opendj/opendj',
    owner  => 'root',
    group  => 'root',
  }

  exec { '/usr/sbin/update-rc.d opendj defaults':
    command => '/usr/sbin/update-rc.d opendj defaults',
    unless  => '/usr/sbin/update-rc.d opendj defaults |grep \'already exist\'',
    require => File['/etc/init.d/opendj'],
  }
}
