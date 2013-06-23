## Load the types the data service requires
import_types_from 'base'
# Defines a data service model
module Tutorials
  data_service_type 'CommandGeneratorSrv' do
    output_port 'cmd', '/base/MotionCommand2D'
  end
end

#### MODELLING
# This part does not need any running components
#
# Make the needed oroGen projects available. The names are
# oroGen project names.
using_task_library 'controldev'
using_task_library 'rock_tutorial'
using_task_library 'tut_brownian'

Controldev::JoystickTask.provides Tutorials::CommandGeneratorSrv, :as => 'cmd'
TutBrownian::Task.provides Tutorials::CommandGeneratorSrv, :as => 'cmd'

module Tutorials
  # Declare the composition
  class RockControl < Syskit::Composition
    # With one joystick. Note that the oroGen project names
    # are converted from snake_case to CamelCase (controldev
    # => Controldev, rock_tutorial => RockTutorial). This is
    # done consistently in the system management layer
    add CommandGeneratorSrv, :as => "cmd"
    # And one rock
    add RockTutorial::RockTutorialControl, :as => "rock"
    # Create any unique connection possible, by matching input
    # and output ports of the same data type. If ambiguities
    # exist, an error is generated
    cmd_child.connect_to rock_child

    conf 'slow',
        cmd_child => ['default', 'slow']
  end
end

#### SYSTEM REQUIREMENTS
# This part specifies what should actually run
#
# Tell the system which deployments to use. The names are
# deployment names, i.e.  the name given to the deployment
# "deployment_name" blocks in oroGen projects
Syskit.conf.use_deployment 'joystick'
Syskit.conf.use_deployment 'rock_tutorial'
Syskit.conf.use_deployment 'brownian'

# Finally, ask the system to run such a composition
define 'joystick', Tutorials::RockControl.use(Controldev::JoystickTask)
define 'random', Tutorials::RockControl.use(TutBrownian::Task)
define 'random_slow', Tutorials::RockControl.use(TutBrownian::Task.use_conf('default', 'slow'))
define 'random_slow2', Tutorials::RockControl.use(TutBrownian::Task).use_conf('slow')
