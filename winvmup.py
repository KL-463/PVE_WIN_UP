import os
import time
import evdev
import select
import subprocess
import logging
import logging.handlers

def setup_logger():
    logger = logging.getLogger("win-vm")
    logger.setLevel(logging.DEBUG)
    handler = logging.handlers.SysLogHandler(address='/dev/log')
    logger.addHandler(handler)
    return logger

def get_keyboard_devices():
    return {dev.fd: dev for dev in [evdev.InputDevice(fn) for fn in evdev.list_devices()] if "keyboard" in dev.name.lower()}

def check_and_start_vm(vm_id, logger):
    cmd = f'qm status {vm_id}'
    try:
        result = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        logger.debug(result.stdout)
        if 'status: stopped' in result.stdout:
            logger.debug(f'qm start {vm_id}')
            subprocess.run(f'qm start {vm_id}', shell=True, check=True)
            time.sleep(10)
    except subprocess.CalledProcessError as e:
        logger.warning(f"Command '{e.cmd}' returned non-zero exit status {e.returncode}: {e.output}")

def main():
    logger = setup_logger()
    vm_id = 105

    leftmeta_pressed = False
    alt_pressed = False
    devices = get_keyboard_devices()

    while True:
        try:
            if not devices:
                time.sleep(1)
                devices = get_keyboard_devices()
                continue

            r, _, _ = select.select(devices, [], [], 1)
            for fd in r:
                for event in devices[fd].read():
                    if event.type == evdev.ecodes.EV_KEY:
                        key_event = evdev.KeyEvent(event)
                        logger.debug(f"Keycode: {key_event.keycode}, Keystate: {key_event.keystate}")

                        if key_event.keycode == 'KEY_LEFTMETA':
                            leftmeta_pressed = key_event.keystate != 0
                        elif key_event.keycode == 'KEY_LEFTALT' or key_event.keycode == 'KEY_RIGHTALT':
                            alt_pressed = key_event.keystate != 0

                        if leftmeta_pressed and alt_pressed:
                            logger.debug("Win + Alt combination pressed")
                            check_and_start_vm(vm_id, logger)
        except KeyboardInterrupt:
            logger.warning('KeyboardInterrupt')
            break
        except Exception as e:
            logger.warning(f"Unexpected error: {str(e)}")
            devices = get_keyboard_devices()

if __name__ == "__main__":
    main()
