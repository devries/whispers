FROM ghcr.io/gleam-lang/gleam:v1.7.0-erlang-alpine

# Add project code
COPY . /builder/

# Compile the project
RUN cd /builder \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /builder

# Run the server
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
