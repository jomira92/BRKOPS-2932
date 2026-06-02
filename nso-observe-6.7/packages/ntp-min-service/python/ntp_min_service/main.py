import ncs
from ncs.application import Service


class NtpMinServiceCallbacks(Service):
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        template = ncs.template.Template(service)
        ntp_server = str(service.ntp_server)

        device_names = []
        try:
            device_names = [str(name) for name in service.device.as_list()]
        except Exception:
            device_names = [str(name) for name in service.device]

        for device_name in device_names:
            vars = ncs.template.Variables()
            vars.add("DEVICE", device_name)
            vars.add("NTP_SERVER", ntp_server)

            try:
                ned_id = str(root.devices.device[device_name].device_type.cli.ned_id)
            except Exception:
                self.log.warning("Skipping device %s: unable to read NED ID", device_name)
                continue

            if "cisco-iosxr-cli" in ned_id:
                template.apply("ntp-min-service-iosxr", vars)
            elif "cisco-ios-cli" in ned_id:
                template.apply("ntp-min-service-ios", vars)
            else:
                self.log.info("Skipping unsupported device %s with NED ID %s", device_name, ned_id)

        return proplist


class Main(ncs.application.Application):
    def setup(self):
        self.log.info("ntp-min-service setup")
        self.register_service("ntp-min-servicepoint", NtpMinServiceCallbacks)

    def teardown(self):
        self.log.info("ntp-min-service teardown")
