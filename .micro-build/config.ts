import {MicroBuildConfig, ELabelNames, EPlugins} from "./x/microbuild-config";
import {JsonEnv} from "../.jsonenv/_current_result.json.d.ts";
declare const build: MicroBuildConfig;
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

build.isInChina(JsonEnv.gfw.isInChina, JsonEnv.gfw);
build.systemInstall('bash');

build.forwardPort(53, 'udp').publish(53);
build.forwardPort(53, 'tcp').publish(53);

build.startupCommand('./run.sh');
build.shellCommand('bash');

build.dockerRunArgument('--cap-add=NET_ADMIN');
// build.runArgument('log-facility', 'log target (can not edit)', '-');

build.specialLabel(ELabelNames.alias, ['dns']);

build.environmentVariable('IS_CHINA', JsonEnv.gfw.isInChina? 'yes' : '');

build.appendDockerFile('build/config.Dockerfile');
build.volume('./etc/dnsmasq.d', '/etc/dnsmasq.d');

build.disablePlugin(EPlugins.jenv);

build.dependService('host-generator', 'http://github.com/GongT/hosts-generator.git');
build.dockerRunArgument('--volumes-from=host-generator');
