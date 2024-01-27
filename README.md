# About

This is the Infrastructure repository for my [Personal Portfolio Project](https://github.com/xamos-portfolio).

This repository will contain the configuration for the required infrastructure to host the website, primarily using OpenTofu.

The resources provisioned through this configuration will primarily be on [Google Cloud Platform](https://cloud.google.com). However, the domain name used for the portfolio website (xamos.org) is hosted in [Route 53](https://aws.amazon.com/route53/) on Amazon Web Services.

Subdomains will be provisioned via this configuration and delegated to [Google Cloud DNS](https://cloud.google.com/dns/).
