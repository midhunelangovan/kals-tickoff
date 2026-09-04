package io.kals.tickoff;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = {"io.kals.core", "io.kals.tickoff"})
public class TickoffApplication {

	public static void main(String[] args) {
		SpringApplication.run(TickoffApplication.class, args);
	}

}
