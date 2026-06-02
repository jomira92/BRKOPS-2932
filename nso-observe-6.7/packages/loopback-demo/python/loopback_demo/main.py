import time

import ncs
from ncs.application import Service


class LoopbackDemoCallbacks(Service):
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        delay_seconds = int(service.sleep_seconds)
        if delay_seconds > 0:
            self.log.info(
                "loopback-demo %s sleeping %s second(s) before template apply",
                service.name,
                delay_seconds,
            )
            time.sleep(delay_seconds)

        device_name = str(service.device)
        loopback_number = str(service.loopback_number)
        ip_address = str(service.ip_address)

        vars = ncs.template.Variables()
        vars.add("DEVICE", device_name)
        vars.add("LOOPBACK_NUMBER", loopback_number)
        vars.add("IPV4_ADDRESS", ip_address)
        vars.add("DESCRIPTION", f"loopback-demo {service.name}")

        template = ncs.template.Template(service)

        try:
            ned_id = str(root.devices.device[device_name].device_type.cli.ned_id)
        except Exception:
            self.log.warning("Skipping device %s: unable to read NED ID", device_name)
            return proplist

        if "cisco-iosxr-cli" in ned_id:
            template.apply("loopback-demo-iosxr", vars)
        elif "cisco-ios-cli" in ned_id:
            template.apply("loopback-demo-ios", vars)
        else:
            self.log.info("Skipping unsupported device %s with NED ID %s", device_name, ned_id)

        return proplist


class Main(ncs.application.Application):
    def setup(self):
        self.log.info("loopback-demo setup")
        self.register_service("loopback-demo", LoopbackDemoCallbacks)

    def teardown(self):
        self.log.info("loopback-demo teardown")
