package com.redhat.samples;

import com.redhat.samples.Contract;
import com.redhat.samples.ContractRepository;
import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Path("/contracts")
public class ContractResource {

    private static final Logger LOGGER = LoggerFactory.getLogger(ContractResource.class);

    @Inject
    ContractRepository repository;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<List<Contract>> getAllContracts() {
        LOGGER.info("GET /contracts called");

        return repository.listAll()
            .onItem().invoke(contracts -> LOGGER.info("Fetched {} contracts", contracts.size()))
            .onFailure().invoke(e -> LOGGER.error("Failed to fetch contracts", e));
    }
}