import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
pub contract Entity: NonFungibleToken { 
     pub var totalSupply: UInt64  

    pub event ContractInitialized() 

    pub event Withdraw(id: UInt64, from: Address?)  
    pub event Deposit(id: UInt64, to: Address?)  
    pub event GeneratorCreated()  
    pub event ElementGenerateSuccess(hex: String)  
    pub event ElementGenerateFailure(hex: String)  
    pub event ElementDeposit(id: UInt64, hex: String)  
    pub event CollectionCreated()

    // 元特征  
    pub struct MetaFeature {
        pub let bytes: [UInt8]
        pub let raw: String?
        init(bytes: [UInt8], raw: String?) {
            self.bytes = bytes
            self.raw = raw
        } 
    }

    // 元要素  
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let feature: MetaFeature
        init(id: UInt64, feature: MetaFeature){
            self.id = id
            self.feature = feature
        }
        
        pub fun getViews(): [Type] {
            return [Type<MetaFeature>()]
        }
    
        pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
               case Type<MetaFeature>():
               return self.feature
            }  
             return nil 
            }
        }

        pub resource interface ExampleProvider {
            pub fun withdrawByHex(hex: String): @NFT {
                post {
                       String.encodeHex(result.feature.bytes) == hex: "The hex of the withdrawn token must be the same as the requested hex"  
                     }
            }  
        }

        pub resource Collection : ExampleProvider, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
            pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}    
            pub var hex2id: {String: UInt64}    
            pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
                let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("NFT does not exist in the collection!")      
                emit Withdraw(id: withdrawID, from: self.owner?.address!)      
                   return <- token    
            }    

            pub fun withdrawByHex(hex: String): @NonFungibleToken.NFT { 
                let id = self.hex2id[hex]?? panic("no resource")      
                return <- (self.ownedNFTs.remove(key: id) as! @NonFungibleToken.NFT)    
            }

             pub fun deposit(token: @NonFungibleToken.NFT) {
                 let element <- token as! @NFT      
                 let hex = String.encodeHex(element.feature.bytes)      
                 self.hex2id[hex] = element.id      
                 let oldtoken <- self.ownedNFTs[element.id] <- (element as! @NonFungibleToken.NFT)      
                 emit ElementDeposit(id: element.id, hex: hex)      
                 destroy old   
            }    
            
            pub fun getIDs(): [UInt64] {      
                return self.ownedNFTs.keys    
            }    
            
            pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {      
                return &self.ownedNFTs[id] as &NonFungibleToken.NFT    
            }

            pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
                let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT        
                let element  = nft as! &EntityNFT.NFT        
                return element as &AnyResource{MetadataViews.Resolver
            }     
                
        } 
                   
        init() {            
            self.ownedNFTs <- {}    
        }    
        
        destroy() { 
            destroy self.ownedNFTs    
        }  
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        emit CollectionCreated()    
        let collection <- create Collection()    
        return <- collection  
    }

    // 特征收集器  
    pub resource Generator {    
        pub let features: {String: MetaFeature}    
        init() {      
            self.features = {}    
        }

        pub fun generate(        
            receiver: &{NonFungibleToken.CollectionPublic},        
            feature: MetaFeature) {      
                // 只收集唯一的 bytes      
                let hex = String.encodeHex(feature.bytes)      
                if self.features.containsKey(hex) == false {                
                    let nft <- create NFT(id: EntityNFT.totalSupply, feature: feature)        
                    self.features[hex] = feature        
                    EntityNFT.totalSupply = EntityNFT.totalSupply + UInt64(1)        
                    emit ElementGenerateSuccess(hex: hex)        
                    receiver.deposit(token: <-nft)       
                } else {        
                    emit ElementGenerateFailure(hex: hex)      
                }    
            }  
    }

    init() {    
        
        self.totalSupply = 0   

        // 保存到存储空间    
        self.account.save(      
            <- create Generator(),      
            to: /storage/ElementGenerator    
        )    

        emit GeneratorCreated()    

        // 链接到公有空间    
        self.account.link<&Generator>(      
            /public/ElementGenerator,
                // 共有空间      
            target: /storage/ElementGenerator 
            // 目标路径    
        )    

        // collection setup    
        self.account.save(      
            <- self.createEmptyCollection(),      
            to: /storage/LocalEntityCollection    
        )    
        self.account.link<&EntityNFT.Collection>(      
            /public/LocalEntityCollection,      
            target: /storage/LocalEntityCollection    
        )      
            
        emit ContractInitialized()  
    }

}