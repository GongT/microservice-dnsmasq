import {MicroBuildHelper} from "./.micro-build/x/microbuild-helper";
import {MicroBuildConfig, ELabelNames, EPlugins} from "./.micro-build/x/microbuild-config";
import {JsonEnv} from "./.jsonenv/_current_result";
declare const build: MicroBuildConfig;
declare const helper: MicroBuildHelper;
/*
 +==================================+
 | <**DON'T EDIT ABOVE THIS LINE**> |
 | THIS IS A PLAIN JAVASCRIPT FILE  |
 |   NOT A TYPESCRIPT OR ES6 FILE   |
 |    ES6 FEATURES NOT AVAILABLE    |
 +==================================+
 */

const projectName = 'microservice-dnsmasq';

build.baseImage('alpine');
build.projectName(projectName);
build.domainName(projectName + '.' + JsonEnv.baseDomainName);

build.isInChina(JsonEnv.gfw.isInChina);
build.systemInstallMethod('apk');
build.systemInstall('bash', 'dnsmasq', 'inotify-tools');

build.forwardPort(53, 'udp').publish(53);
build.forwardPort(53, 'tcp').publish(53);

build.startupCommand('./run.sh');
build.shellCommand('bash');

build.dockerRunArgument('--cap-add=NET_ADMIN');
// build.runArgument('log-facility', 'log target (can not edit)', '-');

build.specialLabel(ELabelNames.alias, ['dns']);

build.appendDockerFile('build/config.Dockerfile');
build.volume('./etc/dnsmasq.d', '/etc/dnsmasq.d');
build.volume('/etc', './host-etc');

build.disablePlugin(EPlugins.jenv);
