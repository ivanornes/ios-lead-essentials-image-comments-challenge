//
//  FeedImageCommentsPresenter.swift
//  EssentialFeed
//
//  Created by Ivan Ornes on 10/3/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public protocol FeedImageCommentsView {
	func display(_ viewModel: FeedImageCommentsViewModel)
}

public final class FeedImageCommentsPresenter {
	private let feedImageCommentsView: FeedImageCommentsView
	private let loadingView: FeedLoadingView
	private let errorView: FeedErrorView
	
	private var feedImageCommentsLoadError: String {
		return NSLocalizedString("FEED_VIEW_CONNECTION_ERROR",
			 tableName: "Feed",
			 bundle: Bundle(for: FeedPresenter.self),
			 comment: "Error message displayed when we can't load the image feed comments from the server")
	}
	
	public init(feedImageCommentsView: FeedImageCommentsView, loadingView: FeedLoadingView, errorView: FeedErrorView) {
		self.feedImageCommentsView = feedImageCommentsView
		self.loadingView = loadingView
		self.errorView = errorView
	}
	
	public static var title: String {
		return NSLocalizedString("FEED_COMMENTS_VIEW_TITLE",
			 tableName: "Feed",
			 bundle: Bundle(for: FeedImageCommentsPresenter.self),
			 comment: "Title for the comments view")
	}
	
	public func didStartLoadingComments() {
		errorView.display(.noError)
		loadingView.display(FeedLoadingViewModel(isLoading: true))
	}
	
	public func didFinishLoadingComments(with comments: [FeedImageComment]) {
		feedImageCommentsView.display(FeedImageCommentsPresenter.map(comments))
		loadingView.display(FeedLoadingViewModel(isLoading: false))
	}
	
	public func didFinishLoadingComments(with error: Error) {
		errorView.display(.error(message: feedImageCommentsLoadError))
		loadingView.display(FeedLoadingViewModel(isLoading: false))
	}
	
	public static func map(_ comments: [FeedImageComment],
						   referenceDate: Date = Date(),
						   locale: Locale = .current,
						   calendar: Calendar = .current) -> FeedImageCommentsViewModel {
		let formatter = RelativeDateTimeFormatter()
		formatter.locale = locale
		formatter.calendar = calendar
		return .init(comments: comments.map {
			FeedImageCommentViewModel(message: $0.message,
									  creationDate: formatter.localizedString(for: $0.createdAt, relativeTo: referenceDate),
									  author:$0.author.username)
		})
	}
}
