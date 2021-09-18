FROM perl:latest
RUN apt-get update
RUN apt-get install --yes libgd-dev
RUN mkdir /app
RUN cd /app && git clone https://alexschroeder.ch/cgit/face-generator
RUN cd /app/face-generator && cpanm --notest File::ShareDir::Install .

# or install from CPAN
# RUN cpanm --notest Game::FaceGenerator
