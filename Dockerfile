# Build the manager binary
FROM registry.access.redhat.com/ubi8/go-toolset:1.16.12-2 as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o manager main.go

# Use ubi micro as minimal base image to package the manager binary
# Refer to https://catalog.redhat.com/software/containers/ubi8-micro/601a84aadd19c7786c47c8ea for more details
FROM registry.access.redhat.com/ubi8-micro:8.5-596
WORKDIR /
COPY --from=builder /workspace/manager .

# rook dynamic loader
COPY ./rook.jar /var/rookout/rook.jar

USER 65532:65532

ENTRYPOINT ["/manager"]
