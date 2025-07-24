package com.redhat.samples;

import com.redhat.samples.Contract;
import io.quarkus.hibernate.reactive.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class ContractRepository implements PanacheRepository<Contract> {
}