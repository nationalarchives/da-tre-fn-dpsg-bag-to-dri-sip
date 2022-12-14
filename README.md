# tre-fn-dpsg-bag-to-dri-sip

* [GitHub Actions](#github-actions)
* [GitHub Action Secrets](#github-action-secrets)
* [Using 'aws codeartifact login'](#using-aws-codeartifact-login)
* [Using 'aws codeartifact get-authorization token'](#using-aws-codeartifact-get-authorization-token)

## GitHub Actions

| Action | Description |
| --- | --- |
| [`.github/workflows/build-deploy-and-tag-ecr-image.yml`](.github/workflows/build-deploy-and-tag-ecr-image.yml) | Gets next git version tag<br>Builds and deploys Docker image to ECR<br>If successful, tags git with new version |

## GitHub Action Secrets

Secret for main AWS authentication (using OpenID Connect):

| Name                         | Description                                          |
| ---------------------------- | ---------------------------------------------------- |
| AWS_OPEN_ID_CONNECT_ROLE_ARN | ARN of AWS role used to authenticate GitHub with AWS |

Other secrets:

| Name                                | Description                                                              |
| ----------------------------------- | ------------------------------------------------------------------------ |
| AWS_CODEARTIFACT_REPOSITORY_NAME    | Name of AWS CodeArtifact repository to log in to for additional packages |
| AWS_CODEARTIFACT_REPOSITORY_DOMAIN  | Name of AWS CodeArtifact repository's domain                             |
| AWS_CODEARTIFACT_REPOSITORY_ACCOUNT | The AWS account ID that owns the CodeArtifact                            |
| AWS_REGION                          | The AWS region to use for CodeArtifact and ECR                           |

## Using 'aws codeartifact login'

```bash
# Create a Python virtual environment
python3 -m venv .venv
. ./.venv/bin/activate

# Log in to AWS codeartifact
aws codeartifact login \
  --tool pip \
  --repository "${AWS_CODEARTIFACT_REPOSITORY_NAME}" \
  --domain "${AWS_CODEARTIFACT_REPOSITORY_DOMAIN}" \
  --domain-owner "${AWS_CODEARTIFACT_REPOSITORY_ACCOUNT}" \
  --region "${AWS_CODEARTIFACT_REPOSITORY_REGION}" \
  --profile "${AWS_PROFILE}"

# Install required libraries from AWS codeartifact
pip install \
  --require-virtualenv \
  --requirement requirements.txt
```

## Using 'aws codeartifact get-authorization token'

Note that environment variable `PIP_INDEX_URL` is passed (using `--build-arg`)
to the `Dockerfile`, where it is made accessible with `ARG PIP_INDEX_URL`, so
the `RUN` command's `pip install` process will find and use it:

```bash
# Get AWS codeartifact authentication token
CA_AUTH_TOKEN="$( \
  aws codeartifact get-authorization-token \
  --duration "${AUTH_TOKEN_DURATION}" \
  --domain "${CA_DOMAIN}" \
  --domain-owner "${AWS_ACCOUNT_ID}" \
  --query authorizationToken \
  --output text \
)"

# Create pip access URL:
export PIP_INDEX_URL=https://${CA_AUTH_USERNAME}:${CA_AUTH_TOKEN}@${CA_DOMAIN}-${AWS_ACCOUNT_ID}.d.codeartifact.${AWS_REGION}.amazonaws.com/pypi/${CA_REPOSITORY_NAME}/simple/"
```

Example `Dockerfile` using `PIP_INDEX_URL` (gets used by `pip install` command):

```dockerfile
FROM public.ecr.aws/lambda/python:3.8

# Loading Variables from Github Actions environment
ARG PIP_INDEX_URL

# Copy function code
COPY tre_bagit_to_dri_sip.py ${LAMBDA_TASK_ROOT}
COPY tre_bagit.py ${LAMBDA_TASK_ROOT}
COPY tre_bagit_transforms.py ${LAMBDA_TASK_ROOT}
# Copy schemas that will be added to dri-sip
COPY closure-schema.txt ${LAMBDA_TASK_ROOT}
COPY metadata-schema.txt ${LAMBDA_TASK_ROOT}

# Install the function's dependencies using file requirements.txt
COPY requirements.txt ./requirements.txt
RUN  yum -y update \
    && yum clean all \
    && pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "tre_bagit_to_dri_sip.handler" ]
```

Passing host `PIP_INDEX_URL` environment variable to a `docker build`:

```bash
docker build \
  --build-arg PIP_INDEX_URL \
  --tag "${REGISTRY}/${REGISTRY_PATH}/${IMAGE_NAME}:${IMAGE_VERSION}" \
  "${DOCKERFILE_DIR}"
```
