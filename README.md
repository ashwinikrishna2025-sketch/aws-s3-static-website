# AWS S3 Static Website with Terraform

A beginner-friendly Terraform project that hosts a static website on **Amazon S3**.
Every AWS resource is defined as code, so you can create the whole site with one
command and delete it with another.

## What it creates

| Resource | Purpose |
| --- | --- |
| `aws_s3_bucket` | Stores the website files (name gets a random suffix so it's globally unique) |
| `aws_s3_bucket_website_configuration` | Turns on S3 static website hosting (`index.html` / `error.html`) |
| `aws_s3_bucket_public_access_block` | Allows a public read policy, still blocks public ACLs |
| `aws_s3_bucket_policy` | Lets anyone **read** (not change) the files |
| `aws_s3_object` | Uploads everything in `website/` with the right content type |

```
website/ ──terraform apply──▶ S3 bucket (website hosting on) ──▶ http://<bucket>.s3-website-<region>.amazonaws.com
```

## Project layout

```
.
├── versions.tf               # Terraform + provider versions, AWS provider settings
├── variables.tf              # Inputs (region, project name)
├── main.tf                   # The S3 bucket, website config, policy, file uploads
├── outputs.tf                # Prints the bucket name and website URL
├── terraform.tfvars.example  # Copy to terraform.tfvars to set your own values
└── website/                  # The site itself - edit these files
    ├── index.html
    ├── error.html
    └── style.css
```

## Prerequisites

1. An AWS account.
2. [Terraform](https://developer.hashicorp.com/terraform/install) 1.5 or newer.
3. AWS credentials on your machine. The easiest way is the
   [AWS CLI](https://aws.amazon.com/cli/) and `aws configure`, using an access key
   from an **IAM user** (not your root account) with S3 permissions.

## Deploy

```bash
# 1. (Optional) set your own name/region
cp terraform.tfvars.example terraform.tfvars

# 2. Download the AWS provider
terraform init

# 3. Preview what will be created - nothing changes yet
terraform plan

# 4. Create it (type "yes" when asked)
terraform apply
```

When it finishes, Terraform prints `website_url`. Open it in your browser.

## Update the site

Edit any file in `website/`, then run `terraform apply` again. Only the changed
files are re-uploaded.

## Tear it down

```bash
terraform destroy
```

This deletes the bucket and every file in it.

## Cost

S3 storage and requests for a small site like this are within the AWS Free Tier
for new accounts and cost cents at most otherwise. Still, run `terraform destroy`
when you're done experimenting.

## Troubleshooting

- **`AccessDenied` when creating the bucket policy** - your AWS account may have
  *account-level* "Block Public Access" turned on. Check
  S3 console → *Block Public Access settings for this account*.
- **`No valid credential sources found`** - run `aws configure` (or set
  `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` environment variables).
- **Site shows `403 Forbidden`** - wait a minute after `apply`; the policy can take
  a moment to apply.

## Ideas for next steps

- Add **CloudFront** in front of the bucket for HTTPS and caching.
- Store Terraform state remotely in S3 so a team can share it.
- Add a **GitHub Actions** workflow that runs `terraform fmt -check` and
  `terraform validate` on every pull request.
- Use a custom domain with **Route 53**.
