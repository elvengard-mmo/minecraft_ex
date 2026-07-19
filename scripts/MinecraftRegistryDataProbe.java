import com.google.gson.JsonParser;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import net.minecraft.SharedConstants;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.RegistryDataLoader;
import net.minecraft.resources.Identifier;
import net.minecraft.server.Bootstrap;
import net.minecraft.server.packs.PackLocationInfo;
import net.minecraft.server.packs.PackType;
import net.minecraft.server.packs.PathPackResources;
import net.minecraft.server.packs.repository.PackSource;
import net.minecraft.server.packs.resources.MultiPackResourceManager;
import net.minecraft.tags.TagLoader;

public final class MinecraftRegistryDataProbe {
    public static void main(String[] args) throws IOException {
        SharedConstants.tryDetectVersion();
        Bootstrap.bootStrap();

        var version = SharedConstants.getCurrentVersion();
        var generatedPath = Path.of(args[0]);
        var dataPath = generatedPath.resolve("data");
        var registryEntries = new LinkedHashMap<Identifier, Map<Identifier, Integer>>();

        Bootstrap.realStdoutPrintln("__MINECRAFT_EX_VERSION__\t" + version.name());
        Bootstrap.realStdoutPrintln("__MINECRAFT_EX_PROTOCOL__\t" + version.protocolVersion());

        for (var registry : RegistryDataLoader.SYNCHRONIZED_REGISTRIES) {
            var registryId = registry.key().identifier();
            var entryIds = entryIds(dataPath, registryId);

            registryEntries.put(registryId, protocolIds(entryIds));

            Bootstrap.realStdoutPrintln("__MINECRAFT_EX_REGISTRY__\t" + registryId);

            for (var entryId : entryIds) {
                Bootstrap.realStdoutPrintln("__MINECRAFT_EX_ENTRY__\t" + entryId);
            }
        }

        addStaticRegistries(generatedPath, registryEntries);
        printTags(generatedPath, registryEntries);
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

    private static Map<Identifier, Integer> protocolIds(List<Identifier> entryIds) {
        var protocolIds = new HashMap<Identifier, Integer>();

        for (var protocolId = 0; protocolId < entryIds.size(); protocolId++) {
            protocolIds.put(entryIds.get(protocolId), protocolId);
        }

        return protocolIds;
    }

    private static void addStaticRegistries(
            Path generatedPath,
            Map<Identifier, Map<Identifier, Integer>> registryEntries) throws IOException {
        var reportPath = generatedPath.resolve("reports/registries.json");

        try (var reader = Files.newBufferedReader(reportPath)) {
            var report = JsonParser.parseReader(reader).getAsJsonObject();
            var registryIds = report.keySet().stream()
                .map(Identifier::parse)
                .sorted()
                .toList();

            for (var registryId : registryIds) {
                if (!registryEntries.containsKey(registryId)) {
                    var entries = report
                        .getAsJsonObject(registryId.toString())
                        .getAsJsonObject("entries");

                    var protocolIds = new HashMap<Identifier, Integer>();

                    for (var entry : entries.entrySet()) {
                        var protocolId = entry
                            .getValue()
                            .getAsJsonObject()
                            .get("protocol_id")
                            .getAsInt();

                        protocolIds.put(Identifier.parse(entry.getKey()), protocolId);
                    }

                    registryEntries.put(registryId, protocolIds);
                }
            }
        }
    }

    private static void printTags(
            Path generatedPath,
            Map<Identifier, Map<Identifier, Integer>> registryEntries) throws IOException {
        var location = new PackLocationInfo(
            "generated",
            Component.literal("generated"),
            PackSource.BUILT_IN,
            Optional.empty()
        );
        var pack = new PathPackResources(location, generatedPath);

        try (var resources = new MultiPackResourceManager(PackType.SERVER_DATA, List.of(pack))) {
            for (var registry : registryEntries.entrySet()) {
                printRegistryTags(resources, registry.getKey(), registry.getValue());
            }
        }
    }

    private static void printRegistryTags(
            MultiPackResourceManager resources,
            Identifier registryId,
            Map<Identifier, Integer> protocolIds) {
        var loader = new TagLoader<Integer>(
            (id, required) -> Optional.ofNullable(protocolIds.get(id)),
            "tags/" + registryId.getPath()
        );
        var loadedTags = loader.load(resources);
        var tags = loader.build(loadedTags);

        if (tags.size() != loadedTags.size()) {
            throw new IllegalStateException("Unable to resolve every tag in " + registryId);
        }

        tags.entrySet().stream()
            .sorted(Map.Entry.comparingByKey())
            .forEach(tag -> {
                var entries = tag.getValue().stream()
                    .map(Object::toString)
                    .collect(Collectors.joining(","));

                Bootstrap.realStdoutPrintln(
                    "__MINECRAFT_EX_TAG__\t"
                        + registryId
                        + "\t"
                        + tag.getKey()
                        + "\t"
                        + entries
                );
            });
    }
}
