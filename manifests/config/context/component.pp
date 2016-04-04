# Definition: tomcat::config::context::component
#
# Configure Nested Component elements in $CATALINA_BASE/conf/context.xml
#
# Parameters:
# - $catalina_base is the base directory for the Tomcat installation.
# - $ensure specifies whether you are trying to add or remove the
#   Resource element. Valid values are 'true', 'false', 'present', and
#   'absent'. Defaults to 'present'.
# - $component_name is the name of the Component to be created, relative to
#   the java:comp/env context.
# - $type is the fully qualified Java class name expected by the web application
#   when it performs a lookup for this resource
# - An optional hash of $additional_attributes to add to the Resource. Should
#   be of the format 'attribute' => 'value'.
# - An optional array of $attributes_to_remove from the Connector.
define tomcat::config::context::component (
  $ensure                = 'present',
  $component_name        = $name,
  $catalina_base         = $::tomcat::catalina_home,
  $additional_attributes = {},
  $attributes_to_remove  = [],
) {
  if versioncmp($::augeasversion, '1.0.0') < 0 {
    fail('Server configurations require Augeas >= 1.0.0')
  }

  validate_re($ensure, '^(present|absent|true|false)$')

  if $component_name {
    $_component_name = $component_name
  } else {
    $_component_name = $name
  }

  # see https://tomcat.apache.org/tomcat-8.0-doc/config/context.html#Nested_Components
  validate_re($_component_name, '^(Cookie Processor|Loader|Manager|Realm|Resources|WatchedResource|JarScanner)$')

  $base_path = "Context/${_component_name}"

  if $ensure =~ /^(absent|false)$/ {
    $changes = "rm ${base_path}"
  } else {
    $set_name = "set ${base_path}"

    if ! empty($additional_attributes) {
      $set_additional_attributes = suffix(prefix(join_keys_to_values($additional_attributes, " '"), "set ${base_path}/#attribute/"), "'")
    } else {
      $set_additional_attributes = undef
    }
    if ! empty(any2array($attributes_to_remove)) {
      $rm_attributes_to_remove = prefix(any2array($attributes_to_remove), "rm ${base_path}/#attribute/")
    } else {
      $rm_attributes_to_remove = undef
    }


    $changes = delete_undef_values(flatten([
      $set_name,
      $set_additional_attributes,
      $rm_attributes_to_remove,
    ]))
  }

  augeas { "context-${catalina_base}-component-${name}":
    lens    => 'Xml.lns',
    incl    => "${catalina_base}/conf/context.xml",
    changes => $changes,
  }
}
