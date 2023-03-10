/*
 * Copyright 2002-2021 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.api.application;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.samples.petclinic.api.dto.OwnerDetails;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;


@Component
public class CustomersServiceClient {

    private final WebClient webClient;

    private final String customersServiceHost;

    private final String customersServicePort;


    public CustomersServiceClient(WebClient webClient,
                                  @Value("${customers-service.host}") String customersServiceHost,
                                  @Value("${customers-service.port}") String customersServicePort) {
        this.webClient = webClient;
        this.customersServiceHost = customersServiceHost;
        this.customersServicePort = customersServicePort;
    }

    public Mono<OwnerDetails> getOwner(final int ownerId) {
        return webClient.get()
            .uri(String.format("http://%s:%s/owners/{ownerId}", customersServiceHost, customersServicePort), ownerId)
            .retrieve()
            .bodyToMono(OwnerDetails.class);
    }
}
