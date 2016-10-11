import {MicroBuildConfig, ELabelNames} from "./x/microbuild-config";
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

build.exposePort(53);
build.forwardPort(53, '5353/udp');

build.startupCommand('./run.sh');
build.shellCommand('bash');

build.nsgLabel(ELabelNames.alias, ['dns']);

build.environmentVariable('IS_DOCKER', 'yes');

build.volume('/etc', '/host_etc');

build.prependDockerFile('build/install.Dockerfile');
build.appendDockerFile('build/config.Dockerfile');

