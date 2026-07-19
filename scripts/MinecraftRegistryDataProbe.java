import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import net.minecraft.SharedConstants;
import net.minecraft.resources.RegistryDataLoader;
import net.minecraft.resources.Identifier;
import net.minecraft.server.Bootstrap;

public final class MinecraftRegistryDataProbe {
    public static void main(String[] args) throws IOException {
        SharedConstants.tryDetectVersion();
        Bootstrap.bootStrap();

        var version = SharedConstants.getCurrentVersion();
        var dataPath = Path.of(args[0]);

        Bootstrap.realStdoutPrintln("__MINECRAFT_EX_VERSION__\t" + version.name());
        Bootstrap.realStdoutPrintln("__MINECRAFT_EX_PROTOCOL__\t" + version.protocolVersion());

        for (var registry : RegistryDataLoader.SYNCHRONIZED_REGISTRIES) {
            var registryId = registry.key().identifier();

            Bootstrap.realStdoutPrintln("__MINECRAFT_EX_REGISTRY__\t" + registryId);

            for (var entryId : entryIds(dataPath, registryId)) {
                Bootstrap.realStdoutPrintln("__MINECRAFT_EX_ENTRY__\t" + entryId);
            }
        }
    }

    private static List<Identifier> entryIds(Path dataPath, Identifier registryId)
            throws IOException {
        var entryIds = new ArrayList<Identifier>();

        try (var namespaces = Files.list(dataPath)) {
            for (var namespacePath : namespaces.filter(Files::isDirectory).toList()) {
                var registryPath = namespacePath.resolve(registryId.getPath());

                if (Files.isDirectory(registryPath)) {
                    collectEntryIds(entryIds, namespacePath, registryPath);
                }
            }
        }

        entryIds.sort(Identifier::compareTo);
        return entryIds;
    }

    private static void collectEntryIds(
            List<Identifier> entryIds,
            Path namespacePath,
            Path registryPath) throws IOException {
        try (var files = Files.walk(registryPath)) {
            for (var filePath : files.filter(Files::isRegularFile).toList()) {
                var entryPath = registryPath.relativize(filePath).toString();

                if (entryPath.endsWith(".json")) {
                    entryPath = entryPath
                        .substring(0, entryPath.length() - ".json".length())
                        .replace(File.separatorChar, '/');

                    entryIds.add(
                        Identifier.fromNamespaceAndPath(
                            namespacePath.getFileName().toString(),
                            entryPath
                        )
                    );
                }
            }
        }
    }
}
