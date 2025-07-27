package com.redhat.samples;

import io.quarkus.hibernate.reactive.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;

@ApplicationScoped
public class ContractRepository implements PanacheRepository<Contract> {
    
    @Inject
    EntityManager entityManager;

    public void register(Contract contract) {
        entityManager.persist(contract);
    }
}