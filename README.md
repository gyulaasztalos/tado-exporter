# tado-exporter
Daily running GitHub Actions workflow which creates docker image of the latest source of tado-exporter (https://github.com/eko/tado-exporter.git)

Using custom Dockerfile with alpine base image and non-root user.
Only x86_64 and ARM64 are supported.
