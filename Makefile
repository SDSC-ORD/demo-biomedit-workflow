.PHONY: run clean get_in

### Config variables

# Podman registry used to push/pull images
REGISTRY = ""
# Name of the image and container used to run the workflow
WF_IMG = $(REGISTRY)"podman-nextflow:latest"
WF_CTNR = "wf-container"
# Container port used for logging
LOG_PORT = 31212
LOG_DIR = "logs"
# Mount point path for pwd in containers
MNT="/repo"

### Containerized commands

# Creates the detached (bakground) container used for workflows
POD_RUN = podman run -dt --name $(WF_CTNR) --privileged -v $(PWD):$(MNT):Z -w $(MNT) --user root
# Executes a single command in the detached workflow container
POD_EXE = podman exec $(WF_CTNR)

### Workflow recipes

# Drop into a shell in the workflow container
get_in:
	podman attach $(WF_CTNR)

# Execute nextflow pipeline in a podman container
run: log
	$(POD_EXE) nextflow run \
		-with-weblog http://localhost:31212 \
		$(MNT)/main.nf

# Start a background logging process in the container
log: start
	$(eval RUN_LOG := $(LOG_DIR)/$(shell date -u +%Y%m%dT%H-%M-%S))
	mkdir -p $(RUN_LOG)
	$(POD_EXE) ./scripts/capture_weblog.sh \
		"$(LOG_PORT)" "$(RUN_LOG)/weblog.json" &

# Restart the container
start: clean
	$(POD_RUN) $(WF_IMG)

# Clean existing workflow container from previous run
clean:
	podman container rm -f $(WF_CTNR) 2>/dev/null || true


### Image management [requires internet connection]

# Push the newly built workflow image
push: wf_img
	podman push $(WF_IMG)

# Build the workflow image (which is based on the podman image)
wf_img: docker/podman-nextflow.Dockerfile pod_img
	podman build -t $(WF_IMG) -f $< .

# Build the podman [in podman] image
pod_img: docker/podman-in-podman.Dockerfile
	podman build -t podman-in-podman:latest -f $< .

