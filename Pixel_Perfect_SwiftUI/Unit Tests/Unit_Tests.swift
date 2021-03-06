//
//  Unit_Tests.swift
//  Unit Tests
//
//  Created by Burhan Aras on 26.12.2021.
//

import XCTest
import Combine
@testable import Pixel_Perfect_SwiftUI

class Unit_Tests: XCTestCase {
    
    func test_mapping_from_DTO_to_movie_should_work_fine(){
        // GIVEN: that we have a MovieDTO
        let dto = MovieDTO(id: 0, title: "title", backdrop_path: "/backdrop", poster_path: "/poster", overview: "overview", vote_average: 1.0, release_date: "2020-03-05")
        let formattedDate = "05.03.2020"
        
        // WHEN: DTO is converted to Movie object
        let sut = Movie.fromDTO(dto: dto)
        
        // THEN: Fields should be correct
        XCTAssertEqual(sut.id, dto.id)
        XCTAssertEqual(sut.title, "\(dto.title) (2020)")
        XCTAssertEqual(sut.overview, dto.overview)
        XCTAssertEqual(sut.rating, "\(dto.vote_average)")
        XCTAssertEqual(sut.releaseDate, formattedDate)
        XCTAssertEqual(sut.backdropURL.absoluteString, "https://image.tmdb.org/t/p/w500\(dto.backdrop_path ?? "")")
        XCTAssertEqual(sut.posterURL.absoluteString, "https://image.tmdb.org/t/p/w500\(dto.poster_path ?? "")")
    }
    
    func test_HomeViewModel_should_show_data_correctly_when_network_returns_successful_data(){
        // GIVEN: that we have a network layer that returns some movies
        let nowPlayingResponse = Result<MoviesResponse, RequestError>.success(MoviesResponse(page: 1, total_pages: 10, results: dummydata(count: 20)))
        let upcomingResponse = Result<MoviesResponse, RequestError>.success(MoviesResponse(page: 1, total_pages: 10, results: dummydata(count: 25)))
        let networkLayer: INetworkLayer = TestNetworkLayer(nowPlayingResponse: nowPlayingResponse, upcomingResponse: upcomingResponse)
        let sut = HomeViewModel(networkLayer: networkLayer)
        
        // WHEN: loadData() of HomeviewModel is called
        sut.loadData()
        
        // THEN: HomeViewModel's data should be same as received data
        XCTAssertEqual(20, sut.nowPlayingMovies.count)
        XCTAssertEqual(25, sut.upcomingMovies.count)
        XCTAssert(sut.errorMessage.isEmpty)
    }
    
    func test_HomeviewModel_should_show_error_message_when_network_fails(){
        // GIVEN: that we have a failing network layer
        let networkLayer: INetworkLayer = TestNetworkLayer(nowPlayingResponse: .failure(RequestError.apiError), upcomingResponse: .failure(RequestError.apiError))
        let sut = HomeViewModel(networkLayer: networkLayer)
        
        // WHEN: loadData() of HomeviewModel is called
        sut.loadData()
        
        // THEN: HomeViewModel's error message must be correct and data should be empty
        XCTAssertEqual(0, sut.nowPlayingMovies.count)
        XCTAssertEqual(0, sut.upcomingMovies.count)
        XCTAssertEqual(RequestError.apiError.localizedDescription, sut.errorMessage)
    }
    
    func test_paging_onHomeViewModel_should_work_fine(){
        // GIVEN: that we have a network layer that returns some data
        let nowPlayingResponse =  [Result<MoviesResponse, RequestError>.success(MoviesResponse(page: 1, total_pages: 10, results: dummydata(count: 20))),
                                   Result<MoviesResponse, RequestError>.success(MoviesResponse(page: 2, total_pages: 10, results: dummydata(count: 20)))]
        let upcomingResponse = [Result<MoviesResponse, RequestError>.success(MoviesResponse(page: 1, total_pages: 10, results: dummydata(count: 30))),
                                Result<MoviesResponse, RequestError>.success(MoviesResponse(page: 2, total_pages: 10, results: dummydata(count: 30)))]
        let networkLayer: INetworkLayer = TestNetworkLayer(nowPlayingResponses: nowPlayingResponse, upcomingResponses: upcomingResponse)
        let sut = HomeViewModel(networkLayer: networkLayer)
        
        // WHEN: HomeViewModel's loadData() and loadNextPageForUpcomingMovies() are called
        sut.loadData()
        sut.loadNextPageForUpcomingMovies()
        
        // THEN: Upcoming movies should be added, nowPlaying should remain same
        XCTAssertEqual(20, sut.nowPlayingMovies.count)
        XCTAssertEqual(60, sut.upcomingMovies.count)
        XCTAssert(sut.errorMessage.isEmpty)
    }
    
    func test_paging_onHomeViewModel_should_stop_when_pages_are_completed(){
        // GIVEN: that we have a network layer that returns some data
        let nowPlayingResponses = [Result<MoviesResponse, RequestError>.success(MoviesResponse(page: 1, total_pages: 1, results: dummydata(count: 20)))]
        let upcomingResponses = [Result<MoviesResponse, RequestError>.success(MoviesResponse(page: 1, total_pages: 1, results: dummydata(count: 30)))]
        let networkLayer: INetworkLayer = TestNetworkLayer(nowPlayingResponses: nowPlayingResponses, upcomingResponses: upcomingResponses)
        let sut = HomeViewModel(networkLayer: networkLayer)
        
        // WHEN: HomeViewModel's loadData() and loadNextPageForUpcomingMovies() are called
        sut.loadData()
        sut.loadNextPageForUpcomingMovies()
        
        // THEN: Upcoming movies should be added, nowPlaying should remain same
        XCTAssertEqual(20, sut.nowPlayingMovies.count)
        XCTAssertEqual(30, sut.upcomingMovies.count)
        XCTAssert(sut.errorMessage.isEmpty)
    }
}


// MARK: - Test network layer that returns successful data or fails
class TestNetworkLayer: INetworkLayer {
    private var nowPlayingResponses: [Result<MoviesResponse, RequestError>]
    private var upcomingResponses: [Result<MoviesResponse, RequestError>]
    
    init(nowPlayingResponse: Result<MoviesResponse, RequestError>, upcomingResponse: Result<MoviesResponse, RequestError>){
        self.nowPlayingResponses = [nowPlayingResponse]
        self.upcomingResponses = [upcomingResponse]
    }
    
    init(nowPlayingResponses: [Result<MoviesResponse, RequestError>], upcomingResponses: [Result<MoviesResponse, RequestError>]){
        self.nowPlayingResponses = nowPlayingResponses
        self.upcomingResponses = upcomingResponses
    }
    
    func getNowPlayingMovies(page: Int) -> AnyPublisher<MoviesResponse, RequestError> {
        return Result<MoviesResponse, RequestError>
            .Publisher(nowPlayingResponses.removeFirst())
            .eraseToAnyPublisher()
    }
    
    func getUpcomingMovies(page: Int) -> AnyPublisher<MoviesResponse, RequestError> {
        return Result<MoviesResponse, RequestError>
            .Publisher(upcomingResponses.removeFirst())
            .eraseToAnyPublisher()
    }
    
}

// MARK: - Dummy data

func dummydata(count: Int) -> [MovieDTO] {
    var data = [MovieDTO]()
    for index in 0..<count {
        let dto = MovieDTO(id: index, title: "title", backdrop_path: "/backdrop", poster_path: "/poster", overview: "overview", vote_average: 1.0, release_date: "2020-03-05")
        data.append(dto)
    }
    return data
}
