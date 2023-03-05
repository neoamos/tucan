
const url = "https://proxy.tucan.to"

export function proxyImage(src, w, h, type){
  type = type || "fit"
  return url + "/i/rs:" + type + ":" + w + ":" + h + "/plain/" + src
}