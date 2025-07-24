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

@Path("/contracts")
public class ContractResource {

    @Inject
    ContractRepository repository;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<List<Contract>> getAllContracts() {
        return repository.listAll(); // 非同期に全件取得
    }
}