package io.kals.tickoff.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.flyway.FlywayConfigurationCustomizer;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;
import java.io.File;
import java.nio.file.Paths;

@Configuration
public class DatabaseConfig {

    public static void ensureDirectoryExists(String datasourceUrl) {
        if (datasourceUrl != null && datasourceUrl.startsWith("jdbc:sqlite:")) {
            String dbPath = datasourceUrl.substring("jdbc:sqlite:".length());
            if (!dbPath.equals(":memory:") && !dbPath.startsWith("file::memory:")) {
                File file = Paths.get(dbPath).toFile();
                File parent = file.getParentFile();
                if (parent != null && !parent.exists()) {
                    parent.mkdirs();
                }
            }
        }
    }

    @Bean
    public FlywayConfigurationCustomizer flywayDirectoryCustomizer(@Value("${spring.datasource.url}") String datasourceUrl) {
        return configuration -> ensureDirectoryExists(datasourceUrl);
    }

    @Bean
    @Primary
    public DataSource dataSource(
            @Value("${spring.datasource.url}") String datasourceUrl,
            @Value("${spring.datasource.driver-class-name:org.sqlite.JDBC}") String driverClassName
    ) {
        ensureDirectoryExists(datasourceUrl);
        return DataSourceBuilder.create()
                .url(datasourceUrl)
                .driverClassName(driverClassName)
                .build();
    }
}
