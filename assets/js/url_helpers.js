
import { nip19 } from "nostr-tools";

export function profile_path(pubkey){
  return "/profile/" + nip19.npubEncode(pubkey)
}

export function post_path(event_id){
  return "/post/" + nip19.noteEncode(event_id)
}


export function user_at(user){
  let npub = nip19.npubEncode(user.pubkey)
  return (user.nip5 ? user.nip5 : "@" + npub.slice(0, 15) + "...")
}