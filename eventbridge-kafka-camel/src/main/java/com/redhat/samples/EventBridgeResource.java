package com.example;

import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.apache.camel.ProducerTemplate;

@Path("/events")
public class EventBridgeResource {

    @Inject
    ProducerTemplate camelProducer;

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response receiveFromEventBridge(String body) {
        // Camel に転送
        camelProducer.sendBody("direct:eventbridge", body);
        return Response.ok().build();
    }
}