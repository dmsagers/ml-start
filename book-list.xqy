xquery version "1.0-ml";

declare option xdmp:output "method = html";

declare function local:sanitizeInput($chars as xs:string?) {
    fn:replace($chars,"[\]\[<>{}\\();%\+]","")
};

declare function local:bookListQuery(
    $searchType as xs:string,
    $searchInput as xs:string
) {
    let $searchQuery :=
            cts:search(/book,
                if ($searchType eq "All") then(())
                else(
                    cts:and-query((
                    cts:directory-query('/bookstore/','infinity'),
                        cts:word-query($searchInput),

                        if ($searchType eq "Title") then (
                            cts:element-word-query(
                                xs:QName("title"), $searchInput)
                        )
                        else if ($searchType eq "Author") then (
                            cts:element-word-query(
                                xs:QName("author"), $searchInput)
                        )
                        else if ($searchType eq "Year") then (
                            cts:element-word-query(
                                xs:QName("year"), $searchInput)
                        )
                        else if ($searchType eq "Price") then (
                            cts:element-word-query(
                                xs:QName("price"), $searchInput)
                        )
                        else if ($searchType eq "Category") then (
                            cts:element-attribute-word-query(
                                xs:QName("book"), xs:QName("category"), $searchInput)
                        )
                        else()
                    ))
                )
            )
    return $searchQuery
};

declare variable $bookList :=
    if (xdmp:get-request-method() eq "GET") then (
        let $searchType := xdmp:get-request-field("searchType")
        let $searchInput := local:sanitizeInput(xdmp:get-request-field("Input"))
        return
            local:bookListQuery($searchType, $searchInput)
    ) else ();

declare function local:editBook($id) {
    let $redirectUri := ("update.xqy?id=" || $id)
    return
        xdmp:redirect-response($redirectUri)
};

(: build the html :)
xdmp:set-response-content-type("text/html"),
'<!DOCTYPE html>',
<html>
    <head>

        <link rel="stylesheet" type="text/css" href="/css/style.css"/>
        <title>Book List</title>
    </head>
    <body>
        <nav id="nav">
            <a href="add-book.xqy" id="add">Add books to Library</a>
            <a href="update.xqy" id="update">Update Library</a>
        </nav>

            <h1 id="mainTitle">Book List</h1>
        <form method="GET" action="book-list.xqy">
            <span>
                <h2>Keyword Search:</h2>
                <select name="searchType" id="searchType">
                    {
                    for $field in ('All', 'Title', 'Author', 'Year', 'Price', 'Category')
                    return
                        <option value="{$field}">{$field}</option>
                    }
                </select>
                <div id='searchBox'>
                    <input name="Input" type="text"/>
                    <input type="submit" value="Search"/>
                </div>
            </span>
        </form>
        {
        if (fn:exists($bookList)) then (
            <h2>Search Results:<br/></h2>,
            <table align="center" style="width:90%">
                        <tr>
                            <th>Title</th>
                            <th>Author</th>
                            <th>Year Published</th>
                            <th>Price</th>
                            <th>Category</th>
                        </tr>
                        {
                        for $book in $bookList
                        order by $book/title
                        return
                            <tr align="center">
                                <td>{data($book/title)}</td>
                                <td>{data($book/author)}</td>
                                <td>{data($book/year)}</td>
                                <td>{data($book/price)}</td>
                                <td>{$book/data(@category)}</td>
                                <td>
                                    <button id="edit-button" onclick="location.href='/update.xqy?id={$book/data(@id)}'">edit</button>
                                </td>
                            </tr>
                        }
                    </table>
        ) else (
            <div>No Search Results Found.</div>
        )
        }

    </body>
</html>