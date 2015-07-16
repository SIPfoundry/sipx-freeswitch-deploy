freeswitch_VER = 1.4.15
freeswitch_TAG = 1.4.4
freeswitch_PACKAGE_REVISION = $(shell cd freeswitch; ../revision-gen $(freeswitch_TAG))
freeswitch_RPM_DEFS = \
	--define="BUILD_NUMBER $(freeswitch_PACKAGE_REVISION)" \
	--define "VERSION_NUMBER $(freeswitch_VER)"
freeswitch_TARBALL = freeswitch-$(freeswitch_VER).tar.bz2
freeswitch_SPEC = freeswitch/freeswitch.spec

PROJECTVER=15.06-stage
REPOHOST = localhost
REPOUSER = stage
REPOPATH = /home/stage/www-root/sipxecs/${PROJECTVER}/externals/CentOS_6/x86_64/
RPMPATH = RPMBUILD/RPMS/x86_64/*.rpm
SSH_OPTIONS = -o UserKnownHostsFile=./.known_hosts -o StrictHostKeyChecking=no
SCP_PARAMS = ${RPMPATH} ${REPOUSER}@${REPOHOST}:${REPOPATH}
CREATEREPO_PARAMS = ${REPOUSER}@${REPOHOST} createrepo ${REPOPATH}
MKDIR_PARAMS = ${REPOUSER}@${REPOHOST} mkdir -p ${REPOPATH}


all: rpm

rpm-dir:
	@rm -rf RPMBUILD; \
	mkdir -p RPMBUILD/{BUILD,SOURCES,RPMS,SRPMS,SPECS};
	

dist: rpm-dir
	cd freeswitch; \
	git archive --format=tar --prefix freeswitch-$(freeswitch_VER)/ HEAD | bzip2 > ../RPMBUILD/SOURCES/$(freeswitch_TARBALL)

rpm: dist
	cp libs/*  RPMBUILD/SOURCES/; \
	cp $(freeswitch_SPEC) RPMBUILD/SPECS/; pwd > RPMBUILD/SPECS/.topdir; cd RPMBUILD/SPECS/; \
	rpmbuild -ba  --define "%_topdir `cat .topdir`/RPMBUILD" $(freeswitch_RPM_DEFS) freeswitch.spec

docker-build:
	docker pull sipfoundrydev/sipx-docker-base-libs; \
	docker run -t --name sipx-fs-builder  -v `pwd`:/BUILD sipfoundrydev/sipx-docker-base-libs \
	/bin/sh -c "cd /BUILD && yum update -y && make"; \
	docker rm sipx-fs-builder


deploy:
	ssh ${SSH_OPTIONS} ${MKDIR_PARAMS}; \
	if [[ $$? -ne 0 ]]; then \
		exit 1; \
	fi; \
	scp ${SSH_OPTIONS} -r ${SCP_PARAMS}; \
	if [[ $$? -ne 0 ]]; then \
		exit 1; \
	fi; \
	ssh ${SSH_OPTIONS} ${CREATEREPO_PARAMS}; \
	if [[ $$? -ne 0 ]]; then \
		exit 1; \
	fi;
