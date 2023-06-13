# Build the dnsmasq-controller binary
FROM golang:1.20 as builder

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
COPY pkg/ pkg/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o dnsmasq-controller main.go

FROM alpine:3.17
RUN apk add --no-cache dnsmasq
COPY --from=builder /workspace/dnsmasq-controller /dnsmasq-controller

RUN sed -i '/^local-service$/s/^/#/' /etc/dnsmasq.conf

RUN mkdir -p /var/lib/tftpboot/
ADD https://github.com/jValdron/ipxe-https/raw/main/ipxe.efi /var/lib/tftpboot/ipxe.efi
ADD https://github.com/jValdron/ipxe-https/raw/main/undionly.kpxe /var/lib/tftpboot/undionly.kpxe
RUN chmod -R 777 /var/lib/tftpboot/

ENTRYPOINT ["/dnsmasq-controller"]
