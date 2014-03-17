class opendj {
  include ::maven
  
  file { ['/opt/opendj','/opt/opendj/instances']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }
}
