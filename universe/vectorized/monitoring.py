import logging

from gym import monitoring
from universe import vectorized

logger = logging.getLogger(__name__)

def Monitor(directory, video_callable=None, force=False, resume=False,
            write_upon_reset=False, uid=None, mode=None):
    class Monitored(vectorized.Wrapper):
        def __init__(self, env):
            super(Monitored, self).__init__(env)

            # Circular dependencies :(
            from universe import wrappers
            # We need to maintain pointers to these to avoid them being
            # GC'd. They have a weak reference to us to avoid cycles.
            # TODO: Unvectorize all envs, not just the first
            self._first_unvectorized_env = wrappers.WeakUnvectorize(self, 0)

            self._monitor = monitoring.MonitorManager(self._first_unvectorized_env)
            self._monitor.start(directory, video_callable, force, resume,
                                write_upon_reset, uid, mode)

        def _step(self, action_n):
            self._monitor._before_step(action_n[0])
            observation_n, reward_n, done_n, info = self.env.step(action_n)
            done_n[0] = self._monitor._after_step(observation_n[0], reward_n[0], done_n[0], info)

            return observation_n, reward_n, done_n, info

        def _reset(self):
            self._monitor._before_reset()
            observation_n = self.env.reset()
            self._monitor._after_reset(observation_n[0])

            return observation_n

        def _close(self):
            super(Monitored, self)._close()
            self._monitor.close()

        def set_monitor_mode(self, mode):
            logger.info("Setting the monitor mode is deprecated and will be removed soon")
            self._monitor._set_mode(mode)

    return Monitored
