package com.redhat.samples;

import io.quarkus.hibernate.reactive.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class ContractRepository implements PanacheRepository<Contract> {
}