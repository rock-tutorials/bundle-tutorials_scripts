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
require 'rock/models/blueprints/pose'
using_task_library 'controldev'
using_task_library 'rock_tutorial'
using_task_library 'tut_brownian'
using_task_library 'tut_sensor'
using_task_library 'tut_follower'

Controldev::JoystickTask.provides Tutorials::CommandGeneratorSrv, :as => 'cmd'
TutBrownian::Task.provides Tutorials::CommandGeneratorSrv, :as => 'cmd'
TutFollower::Task.provides Tutorials::CommandGeneratorSrv, :as => 'cmd'

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

    export rock_child.pose_samples_port
    provides Base::PoseSrv, :as => 'pose'
  end
end

# This is the syntax to add specializations to existing composition models (i.e.
# after the class ... end definition)
Tutorials::RockControl.specialize Tutorials::RockControl.cmd_child => TutFollower::Task do
  # It will need some other task/composition to provide the target pose
  add Base::PoseSrv, :as => "target_pose"
  # And the sensor processing to compute the bearing/distance to target
  add TutSensor::Task, :as => 'sensor'

  # We must specify the port on the sensor child, since
  # there are two matches
  #
  # The rock child is already defined in the 'base' Tutorials::RockControl
  # composition
  target_pose_child.connect_to sensor_child.target_frame_port
  rock_child.connect_to sensor_child.local_frame_port
  sensor_child.connect_to cmd_child
end

#### SYSTEM REQUIREMENTS
# This part specifies what should actually run
#
# Tell the system which deployments to use. The names are
# deployment names, i.e.  the name given to the deployment
# "deployment_name" blocks in oroGen projects
Syskit.conf.use_deployments_from 'tut_deployment'

# Finally, ask the system to run such a composition
define 'joystick', Tutorials::RockControl.use(Controldev::JoystickTask)
define 'random', Tutorials::RockControl.use(TutBrownian::Task)
define 'random_slow', Tutorials::RockControl.use(TutBrownian::Task.with_conf('default', 'slow'))
define 'random_slow2', Tutorials::RockControl.use(TutBrownian::Task).with_conf('slow')
define 'leader',
  Tutorials::RockControl.use(TutBrownian::Task).
    use_deployments(/target/)
define 'follower',
  Tutorials::RockControl.use(TutFollower::Task, leader_def).
    use_deployments(/follower/)
