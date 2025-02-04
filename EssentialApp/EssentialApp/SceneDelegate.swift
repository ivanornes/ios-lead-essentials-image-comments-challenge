//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import UIKit
import CoreData
import Combine
import EssentialFeed

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	
	private lazy var httpClient: HTTPClient = {
		URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
	}()
	
	private lazy var store: FeedStore & FeedImageDataStore = {
		try! CoreDataFeedStore(
			storeURL: NSPersistentContainer
				.defaultDirectoryURL()
				.appendingPathComponent("feed-store.sqlite"))
	}()
	
	private lazy var baseURL: URL = { URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/")! }()
	
	private lazy var remoteFeedLoader: RemoteFeedLoader = {
		RemoteFeedLoader(url: baseURL.appendingPathComponent("feed"), client: httpClient)
	}()
	
	private lazy var localFeedLoader: LocalFeedLoader = {
		LocalFeedLoader(store: store, currentDate: Date.init)
	}()
	
	private lazy var remoteImageLoader: RemoteFeedImageDataLoader = {
		RemoteFeedImageDataLoader(client: httpClient)
	}()
	
	private lazy var localImageLoader: LocalFeedImageDataLoader = {
		LocalFeedImageDataLoader(store: store)
	}()
	
	private func makeRemoteFeedImageCommentsLoader(feedImage: FeedImage) -> RemoteFeedImageCommentsLoader {
		let url = baseURL.appendingPathComponent("image/\(feedImage.id.uuidString)/comments")
		return RemoteFeedImageCommentsLoader(url: url, client: httpClient)
	}
	
	convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore) {
		self.init()
		self.httpClient = httpClient
		self.store = store
	}
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let scene = (scene as? UIWindowScene) else { return }
		
		window = UIWindow(windowScene: scene)
		configureWindow()
	}
	
	private lazy var navigationController = UINavigationController(
		rootViewController: FeedUIComposer.feedComposedWith(
			   feedLoader: makeRemoteFeedLoaderWithLocalFallback,
			   imageLoader: makeLocalImageLoaderWithRemoteFallback,
			imageSelection: displayImage))
	
	func configureWindow() {
		window?.rootViewController = navigationController
		window?.makeKeyAndVisible()
	}
	
	func displayImage(feedImage: FeedImage) {
		let feedImageCommentsViewController = FeedImageCommentsUIComposer
			.feedImageCommentsComposedWith(
				feedImageCommentsLoader: makeRemoteFeedImageCommentsLoader(feedImage: feedImage).loadPublisher)
		navigationController.pushViewController(feedImageCommentsViewController, animated: true)
	}
	
	func sceneWillResignActive(_ scene: UIScene) {
		localFeedLoader.validateCache { _ in }
	}
	
	private func makeRemoteFeedLoaderWithLocalFallback() -> FeedLoader.Publisher {
		return remoteFeedLoader
			.loadPublisher()
			.caching(to: localFeedLoader)
			.fallback(to: localFeedLoader.loadPublisher)
	}
	
	private func makeLocalImageLoaderWithRemoteFallback(url: URL) -> FeedImageDataLoader.Publisher {
		return localImageLoader
			.loadImageDataPublisher(from: url)
			.fallback(to: { [remoteImageLoader, localImageLoader] in
				remoteImageLoader
					.loadImageDataPublisher(from: url)
					.caching(to: localImageLoader, using: url)
			})
	}
}
