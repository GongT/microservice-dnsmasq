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
build.domainName(projectName + '.localdomain');

build.forwardPort(53, 'udp').publish(53);
build.forwardPort(53, 'tcp').publish(53);

build.startupCommand('./run.sh');
build.shellCommand('bash');

build.dockerRunArgument('--cap-add=NET_ADMIN');
// build.runArgument('log-facility', 'log target (can not edit)', '-');

build.nsgLabel(ELabelNames.alias, ['dns']);

build.environmentVariable('IS_DOCKER', 'yes');
build.environmentVariable('IS_CHINA', JsonEnv.isInChina? 'yes' : '');

build.volume('/etc', '/host_etc');

build.prependDockerFile('build/install.Dockerfile');
build.appendDockerFile('build/config.Dockerfile');

build.addPlugin(EPlugins.jenv);
