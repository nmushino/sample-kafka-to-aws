package com.redhat.examples;

import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.apache.camel.ProducerTemplate;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Path("/events")
public class EventBridgeResource {

    private static final Logger logger = LoggerFactory.getLogger(EventBridgeResource.class);

    @Inject
    ProducerTemplate camelProducer;

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response receiveFromEventBridge(String body) {
        logger.info("受信したイベント: {}", body);
        camelProducer.sendBody("direct:eventbridge", body);
        return Response.ok().build();
    }
}