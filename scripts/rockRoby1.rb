#### MODELLING
# This part does not need any running components
#
# Make the needed oroGen projects available. The names are oroGen project names.
using_task_library 'controldev'
using_task_library 'rock_tutorial'

# Declare the composition. The new model can be accessed with either
# Compositions::RockControl or Cmp::RockControl
composition 'RockControl' do
  # With one joystick. Note that the oroGen project names are converted from
  # snake_case to CamelCase (controldev => Controldev, rock_tutorial =>
  # RockTutorial). This is done consistently in the system management layer
  add Controldev::JoystickTask, :as => "joystick"
  # And one rock
  add RockTutorial::RockTutorialControl, :as => "rock"
  # Create any unique connection possible, by matching input and output ports
  # of the same data type. If ambiguities exist, an error is generated
  autoconnect
end

#### SYSTEM REQUIREMENTS
# This part specifies what should actually run
#
# Tell the system which deployments to use. The names are deployment names, i.e.
# the name given to the deployment "deployment_name" blocks in oroGen projects
use_deployment 'rock_tutorial'
use_deployment 'joystick'

# Finally, ask the system to run such a composition
add Cmp::RockControl
