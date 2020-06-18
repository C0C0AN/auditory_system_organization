######################################################
# Generate a Dockerfile and Singularity recipe for building an mvs container.
#
# Steps to build, upload, and deploy the mvs Docker and/or Singularity image:
#
# 1. Create or update the Dockerfile and Singuarity recipe:
# bash generate_mvs_images.sh
#
# 2. Build the docker image:
# docker build -t mvs -f Dockerfile .
# OR
# bash generate_mvs_images.sh docker
#
#    and/or singularity image:
# singularity build mindboggle.simg Singularity
# OR
# bash generate_mvs_images.sh singularity
#
#   and/or both:
# bash generate_mvs_images.sh both
#
# 3. Push to Docker hub:
# (https://docs.docker.com/docker-cloud/builds/push-images/)
# export DOCKER_ID_USER="your_docker_id"
# docker login
# docker tag mvs your_docker_id/mvs:tag  # See: https://docs.docker.com/engine/reference/commandline/tag/
# docker push your_docker_id/mvs:tag
#
# 4. Pull from Docker hub (or use the original):
# docker pull your_docker_id/mvs
#
# In the following, the Docker container can be the original (mvs)
# or the pulled version (ypur_docker_id/mvs:tag), and is given access to /Users/mvs
# on the host machine.
#
# 5. Enter the bash shell of the Docker container, and add port mappings:
# docker run --rm -ti -v /Users/mvs:/home/mvs -p 8888:8888 -p 5000:5000 your_docker_id/mvs
#
#
###############################################################################

image="kaczmarj/neurodocker:0.6.0"

set -e

generate_docker() {
 docker run --rm ${image} generate docker \
            --base neurodebian:stretch-non-free \
            --pkg-manager apt \
            --run-bash 'apt-get update' \
            --install git num-utils gcc g++ curl build-essential \
            --user=mvs \
            --miniconda \
               conda_install="python=3.7 notebook ipython seaborn pandas matplotlib" \
               pip_install='ipywidgets ipyevents jupytext nilearn nistats nibabel mne scikit-learn datalad pysurfer pybids' \
               create_env='mvs' \
               activate=true \
            --run 'mkdir -p ~/.jupyter && echo c.NotebookApp.ip = \"0.0.0.0\" > ~/.jupyter/jupyter_notebook_config.py' \
            --entrypoint="/neurodocker/startup.sh" \
            --cmd jupyter notebook
}

generate_singularity() {
  docker run --rm ${image} generate singularity \
            --base neurodebian:stretch-non-free \
            --pkg-manager apt \
            --run-bash 'apt-get update' \
            --install git num-utils gcc g++ curl build-essential \
            --user=mvs \
            --miniconda \
               conda_install="python=3.7 notebook ipython seaborn pandas matplotlib" \
               pip_install='ipywidgets ipyevents jupytext nilearn nistats nibabel mne scikit-learn datalad pysurfer pybids' \
               create_env='mvs' \
               activate=true \
            --run 'mkdir -p ~/.jupyter && echo c.NotebookApp.ip = \"0.0.0.0\" > ~/.jupyter/jupyter_notebook_config.py' \
            --entrypoint="/neurodocker/startup.sh" 
}

# generate files
generate_docker > Dockerfile
generate_singularity > Singularity

# check if images should be build locally or not
if [ '$1' = 'docker' ]; then
 echo "docker image will be build locally"
 # build image using the saved files
 docker build -t mvs .
elif [ '$1' = 'singularity' ]; then
 echo "singularity image will be build locally"
 # build image using the saved files
 singularity build mvs.simg Singularity
elif [ '$1' = 'both' ]; then
 echo "docker and singularity images will be build locally"
 # build images using the saved files
 docker build -t mvs .
 singularity build mvs.simg Singularity
else
echo "Image(s) won't be build locally."
fi
