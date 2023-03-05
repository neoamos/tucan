import React, { useState, useEffect } from "react";

import { MainHeader } from "../layout";
import { ScrollToTop } from "../components/scroll"
import Tabs from "../components/tabs";
import { useLocation, useParams } from 'react-router-dom';
import { nip19 } from "nostr-tools";
import { ReloadPosts, useTitle, Pagination } from "../components/ui_elements";
import axios from "axios";
import { UserItem } from "../components/user"

export default function Following(){
  const page_size = 50
  let { pubkey, following } = useParams()

  const [loadingState, setLoadingState] = useState("loading")
  const [users, setUsers] = useState([])
  const [totalItems, setTotalItems] = useState(0)
  const [page, setPage] = useState({
    tab: (following == "following" ? 0 : 1), 
    page: 1, offset: 0, limit: page_size}
  )

  let tabs = [
    {
      name: "Following"
    },
    {
      name: "Followers"
    }
  ]

  useTitle(page.tab == 0 ? "Following" : "Followers")

  try{
    pubkey = nip19.decode(pubkey).data
  }catch(e){}

  function setTab(tab){
    setTotalItems(0)
    setPage({
      page: 1,
      offset: 0,
      limit: page_size,
      tab: tab
    })
  }

  function getUsers(){
    setLoadingState("loading")
    let params = {limit: page.limit, offset: page.offset}
    if(page.tab == 0){
      params.following = pubkey
    }else{
      params.followed = pubkey
    }
    axios
    .get("/api/v1/users", {params: params})
    .then(function(resp){
      setLoadingState("ok")
      setTotalItems(resp.data.count)
      setUsers(resp.data.users)
    })
    .catch(function(){
      setLoadingState("err")
    })
  }

  useEffect(() => {
    getUsers()
  }, [page])

  function handlePagination(pageNum, offset, limit){
    setPage({
      ...page,
      page: pageNum,
      offset: offset,
      limit: limit
    })
  }

  let userComponents = users.map((user) => {
    return <UserItem user={user} key={user.pubkey} description={true} follow_button={true} />
  })
  return (
    <div style={{height: "100%"}}>
      <ScrollToTop />
      <MainHeader>
        <h2>{page.tab == 0 ? "Following" : "Followers"}</h2>
      </MainHeader>
      <Tabs tabs={tabs} activeTab={page.tab} setActiveTab={setTab} />
      {loadingState!="ok" ? 
        <ReloadPosts reload={getUsers} state={loadingState} /> : 
        userComponents}
      {totalItems > page_size && <Pagination total_items={totalItems} page_size={page_size} page={page.page} fetch={handlePagination} />}
    </div>
  )
}