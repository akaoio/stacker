export default {
  entry: ['src/index.ts'],
  formats: ["cjs", "esm"],
  dts: true,
  sourcemap: true,
  clean: true,
  target: "node",
  bundle: false,
  external: [
    /^@akaoio\//,
    /^node:/
  ]
}